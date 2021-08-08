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
@notify_manager.register(Notifier::Discord.new(
  token: ENV['DISCORD_TOKEN'],
  client_id: ENV['DISCORD_CLIENT_ID'],
  channel_id: ENV['DISCORD_NOTIFY_CHANNEL_ID'],
))
@notify_manager.register(Notifier::Twitter.new(
  consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
  access_token:        ENV['TWITTER_OAUTH_TOKEN'],
  access_token_secret: ENV['TWITTER_OAUTH_TOKEN_SECRET'],
))

@servers = {}
@client = HTTPClient.new
loop do
  begin
    json = @client.get(ENV['TSKSERVER_API_URL']).body
    data = JSON.parse(json, symbolize_names: true)
    
    data.each do |k, v|
      name, body, status, last_checked_at = k, v[:body], v[:status], v[:last_checked_at]
      
      # NOTE: This is just a workaround due to an insufficient API structure
      if name == 'tskserver'
        @servers[name] ||= ServerInfo.new(
          name: name,
          host: 'mc.ksswre.net',
          website_url: 'https://mc.ksswre.net',
          infos: v[:body],
        )
      end
      begin
        case status
        when 'online'
          if @status_before
            if @status_before != status
              event = Events::ServerUp.new(
                server: @servers[name],
                last_checked_at: last_checked_at,
              )
              @notify_manager.fire_event(event)
            end
          end
          
          @onlines = body[:players][:sample] || []
          if @onlines_before
            onlines_diff = @onlines - @onlines_before
            
            if onlines_diff.size > 0
              event = Events::UserLogined.new(
                server: @servers[name],
                last_checked_at: last_checked_at,
                onlines_diff: onlines_diff,
                onlines: onlines,
              )
              @notify_manager.fire_event(event)
            end
          end
          @onlines_before = @onlines
        else
          if @status_before
            if @status_before != status
              # TODO: API may include error details in body, remove them after API changes
              event = Events::ServerDown.new(
                server: @servers[name],
                last_checked_at: last_checked_at,
                infos: {
                  error: body[:error],
                  detail: body[:detail],
                }
              )
              @notify_manager.fire_event(event)
            end
          end
        end
      rescue => e
        pp e
        puts e.backtrace
      ensure
        @status_before = status
      end
      
      @notify_manager.heartbeat()
    end
  rescue => e
    pp e
    puts e.backtrace
  end
  
  sleep 10
end

