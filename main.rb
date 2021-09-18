require 'json'
require 'httpclient'
require 'pp'
require 'dotenv/load'

require_relative './events'
require_relative './serverinfo'
require_relative './notifiers/notifier'
require_relative './notifymanager'


@notify_manager = NotifyManager.new(
  heartbeat_url: ENV['HEARTBEAT_URL']
)
@notify_manager.register(Notifier::DiscordNotifier.new(
  token: ENV['DISCORD_TOKEN'],
  client_id: ENV['DISCORD_CLIENT_ID'],
  channel_id: ENV['DISCORD_NOTIFY_CHANNEL_ID'],
))
@notify_manager.register(Notifier::TwitterNotifier.new(
  consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
  access_token:        ENV['TWITTER_OAUTH_TOKEN'],
  access_token_secret: ENV['TWITTER_OAUTH_TOKEN_SECRET'],
))

def fetch_status(client, url)
  json = client.get(url).body
  return JSON.parse(json, symbolize_names: true)
end

@servers = {}
@status_before = {}
@onlines_before = {}
@client = HTTPClient.new
loop do
  begin
    data = fetch_status(@client, ENV['TSKSERVER_API_URL'])
    data.each do |k, v|
      name, body, status, last_checked_at = k, v[:body], v[:status], v[:last_checked_at]
      
      events = []
      
      # NOTE: This is just a workaround due to an insufficient API structure
      @servers[name] = ServerInfo.new(
        name: name,
        host: 'mc.ksswre.net',
        website_url: 'https://mc.ksswre.net',
        infos: body,
      )
      if status == 'online'
        if @status_before[name] && @status_before[name] != status
          events << Events::ServerUp.new(
            server: @servers[name],
            last_checked_at: last_checked_at,
          )
        end
        
        onlines = body[:players][:sample] || []
        if @onlines_before[name]
          onlines_diff = onlines - @onlines_before[name]
          
          if onlines_diff.size > 0
            events << Events::UserLogined.new(
              server: @servers[name],
              last_checked_at: last_checked_at,
              onlines_diff: onlines_diff,
              onlines: onlines,
            )
          end
        end
        @onlines_before[name] = onlines
      else
        if @status_before[name] && @status_before[name] != status
          # TODO: API may include error details in body, remove them after API changes
          events << Events::ServerDown.new(
            server: @servers[name],
            last_checked_at: last_checked_at,
            infos: {
              error: body[:error],
              detail: body[:detail],
            }
          )
        end
      end
      
      events.each do |event|
        @notify_manager.fire_event(event)
      end
      
      @status_before[name] = status
    end
  rescue => e
    pp e
    puts e.backtrace
  ensure
    @notify_manager.heartbeat()
    sleep 10
  end
end

