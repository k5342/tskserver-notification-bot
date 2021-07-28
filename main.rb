require 'twitter'
require 'discordrb'
require 'json'
require 'httpclient'
require 'pp'
require 'dotenv/load'

require_relative './events'
require_relative './serverinfo'

class Tweet
  def initialize(twitter)
    @twitter = twitter
  end
  
  def user_login(event)
    tweet("現在 #{event.onlines.size} 人がオンラインです。", event.last_checked_at)
  end
  
  def server_down(event)
    tweet("サーバが落ちました。", event.last_checked_at)
  end
  
  def server_up(event)
    tweet("サーバが起動しました。", event.last_checked_at)
  end
  
  private
  def tweet(message, last_checked_at = Time.now, prefix = '')
    @twitter.update([message, "[#{last_checked_at.to_s}]", '#tskserver'].join(' '))
  end
end

class Discord
  def initialize(bot, channel_id)
    @bot = bot
    @channel_id = channel_id
  end
  
  def user_login(event)
    message = "#{event.onlines_diff.sort_by{|x| x[:id] }.map{|x| "`#{x[:name]}`"}.join(', ')} logined to the server."
    
    embed = Discordrb::Webhooks::Embed.new(
      title: 'Minecraft',
      description: "#{event.server.name} status",
      url: event.server.website_url, # TODO: make as optional
      thumbnail: Discordrb::Webhooks::EmbedThumbnail.new(url: "https://crafatar.com/renders/body/#{event.onlines_diff.first[:id]}"),
      colour: 0x008040,
      fields: [
        Discordrb::Webhooks::EmbedField.new(
          name: 'Onlines Count',
          value: event.onlines.size,
          inline: true
        ),
        Discordrb::Webhooks::EmbedField.new(
          name: 'Onlines',
          value: event.onlines.map{|x| "`#{x[:name]}`"}.join(', '),
          inline: true,
        ),
      ],
      image: Discordrb::Webhooks::EmbedImage.new(
        url: "https://graph.ksswre.net/tskserver?#{Time.now.to_i}"
      ),
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: "last checked at #{event.last_checked_at.to_s}"
      )
    )
    
    discord_post(message, embed)
  end
  
  def server_down(event)
    message = "#{event.server.name} seems to be down"
    
    embed = Discordrb::Webhooks::Embed.new(
      title: 'Minecraft',
      description: "#{event.server.name} status",
      url: event.server.website_url, # TODO: make as optional
      colour: 0x804000,
      fields: [
        Discordrb::Webhooks::EmbedField.new(
          name: 'Status',
          value: event.infos[:error],
          inline: true
        ),
        Discordrb::Webhooks::EmbedField.new(
          name: 'Detail',
          value: event.infos[:detail],
          inline: true
        ),
      ],
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: "last checked at #{event.last_checked_at.to_s}"
      )
    )
    
    discord_post(message, embed)
  end
  
  def server_up(event)
    message = "#{event.server.name} has been started"
    
    embed = Discordrb::Webhooks::Embed.new(
      title: 'Minecraft',
      description: "#{event.server.name} status",
      url: event.server.website_url, # TODO: make as optional
      colour: 0x008040,
      fields: [
        Discordrb::Webhooks::EmbedField.new(
          name: 'Status',
          value: 'Online',
          inline: true
        ),
        Discordrb::Webhooks::EmbedField.new(
          name: 'Version',
          value: event.server.infos[:version][:name],
          inline: true
        ),
      ],
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: "last checked at #{event.last_checked_at.to_s}"
      )
    )
    
    discord_post(message, embed)
  end
  
  private
  def discord_post(message, embed, prefix = '')
    if prefix && !prefix.empty?
      message = [prefix, message].join(' ')
    end
    
    @bot.send_message(@channel_id, message, false, embed)
  end
end

class Notify
  def initialize
    discord = Discordrb::Bot.new(
      token: ENV['DISCORD_TOKEN'],
      client_id: ENV['DISCORD_CLIENT_ID'],
    )
    discord.run :async
    puts "bot invite URL: #{discord.invite_url}"
    @discord = Discord.new(discord, ENV['DISCORD_NOTIFY_CHANNEL_ID'])
    
    twitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end 
    @twitter = Tweet.new(twitter)
    @heartbeat_last_sent_at = -1
    @heartbeat_client = HTTPClient.new
    @heartbeat_url = ENV['HEARTBEAT_URL'] || nil
  end
  
  def user_login(e)
    @discord.user_login(e)
    @twitter.user_login(e)
  end
  
  def server_down(e)
    @discord.server_down(e)
    @twitter.server_down(e)
  end
  
  def server_up(event)
    @discord.server_up(e)
    @twitter.server_up(e)
  end
  
  def heartbeat()
    if @heartbeat_url
      if Time.now.to_i - @heartbeat_last_sent_at >= 60
        @heartbeat_client.get(@heartbeat_url)
        @heartbeat_last_sent_at = Time.now
      end
    end
  end
end

@servers = {}
@notify = Notify.new
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
          host: mc.ksswre.net,
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
              @notify.server_up(event)
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
              @notify.user_login(event)
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
              @notify.server_down(event)
            end
          end
        end
      rescue => e
        pp e
        puts e.backtrace
      ensure
        @status_before = status
      end
      
      @notify.heartbeat()
    end
  rescue => e
    pp e
    puts e.backtrace
  end
  
  sleep 10
end

