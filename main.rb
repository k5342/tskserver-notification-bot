require 'twitter'
require 'discordrb'
require 'json'
require 'httpclient'
require 'pp'
require 'dotenv/load'

class Tweet
  def initialize(twitter)
    @twitter = twitter
  end
  
  def user_login(onlines_diff, onlines, last_checked_at, prefix = '')
    tweet("現在 #{onlines.size} 人がオンラインです。", last_checked_at)
  end
  
  def server_down(name, body, status, last_checked_at)
    tweet("サーバが落ちました。", last_checked_at)
  end
  
  def server_up(name, body, status, last_checked_at)
    tweet("サーバが起動しました。", last_checked_at)
  end
  
  private
  def tweet(message, last_checked_at = Time.now, prefix = '')
    if prefix && !prefix.empty?
      message = [prefix, message].join(' ')
    end
    
    @twitter.update([message, "[#{last_checked_at.to_s}]", '#tskserver'].join(' '))
  end
end

class Discord
  def initialize(bot, channel_id)
    @bot = bot
    @channel_id = channel_id
  end
  
  def user_login(onlines_diff, onlines, last_checked_at, prefix = '')
    message = "#{onlines_diff.sort_by{|x| x[:id] }.map{|x| "`#{x[:name]}`"}.join(', ')} logined to the server."
    
    embed = Discordrb::Webhooks::Embed.new(
      title: 'Minecraft',
      description: "tskserver status",
      url: 'https://mc.ksswre.net/status',
      thumbnail: Discordrb::Webhooks::EmbedThumbnail.new(url: "https://crafatar.com/renders/body/#{onlines_diff.first[:id]}"),
      colour: 0x008040,
      fields: [
        Discordrb::Webhooks::EmbedField.new(
          name: 'Onlines Count',
          value: onlines.size,
          inline: true
        ),
        Discordrb::Webhooks::EmbedField.new(
          name: 'Onlines',
          value: onlines.map{|x| "`#{x[:name]}`"}.join(', '),
          inline: true,
        ),
      ],
      image: Discordrb::Webhooks::EmbedImage.new(
        url: "https://graph.ksswre.net/tskserver?#{Time.now.to_i}"
      ),
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: "last checked at #{last_checked_at.to_s}"
      )
    )
    
    discord_post(message, embed)
  end
  
  def server_down(name, body, status, last_checked_at)
    message = "#{name} seems to be down"
    
    embed = Discordrb::Webhooks::Embed.new(
      title: 'Minecraft',
      description: "#{name} status",
      url: 'https://mc.ksswre.net/',
      colour: 0x804000,
      fields: [
        Discordrb::Webhooks::EmbedField.new(
          name: 'Status',
          value: body[:error],
          inline: true
        ),
        Discordrb::Webhooks::EmbedField.new(
          name: 'Detail',
          value: body[:detail],
          inline: true
        ),
      ],
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: "last checked at #{last_checked_at.to_s}"
      )
    )
    
    discord_post(message, embed)
  end
  
  def server_up(name, body, status, last_checked_at)
    message = "#{name} has been started"
    
    embed = Discordrb::Webhooks::Embed.new(
      title: 'Minecraft',
      description: "#{name} status",
      url: 'https://mc.ksswre.net/',
      colour: 0x008040,
      fields: [
        Discordrb::Webhooks::EmbedField.new(
          name: 'Status',
          value: status,
          inline: true
        ),
        Discordrb::Webhooks::EmbedField.new(
          name: 'Version',
          value: body[:version][:name],
          inline: true
        ),
      ],
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: "last checked at #{last_checked_at.to_s}"
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
    @heartbeat_last_sent_at = Time.at(0)
    @heartbeat_client = HTTPClient.new
    @heartbeat_url = ENV['HEARTBEAT_URL'] || nil
  end
  
  def user_login(onlines_diff, onlines, last_checked_at, prefix = '')
    @discord.user_login(onlines_diff, onlines, last_checked_at, prefix)
    @twitter.user_login(onlines_diff, onlines, last_checked_at, prefix)
  end
  
  def server_down(name, body, status, last_checked_at)
    @discord.server_down(name, body, status, last_checked_at)
    @twitter.server_down(name, body, status, last_checked_at)
  end
  
  def server_up(name, body, status, last_checked_at)
    @discord.server_up(name, body, status, last_checked_at)
    @twitter.server_up(name, body, status, last_checked_at)
  end
  
  def heartbeat()
    if @heartbeat_url
      if Time.now.to_i - @heartbeat_last_sent_at.to_i >= 60
        @heartbeat_client.get(@heartbeat_url)
        @heartbeat_last_sent_at = Time.now
      end
    end
  end
end

@notify = Notify.new
@client = HTTPClient.new
loop do
  begin
    json = @client.get(ENV['TSKSERVER_API_URL']).body
    data = JSON.parse(json, symbolize_names: true)
    
    data.each do |k, v|
      name, body, status, last_checked_at = k, v[:body], v[:status], v[:last_checked_at]
      
      begin
        case status
        when 'online'
          if @status_before
            if @status_before != status
              @notify.server_up(name, body, status, last_checked_at)
            end
          end
          
          @onlines = body[:players][:sample] || []
          if @onlines_before
            onlines_diff = @onlines - @onlines_before
            
            if onlines_diff.size > 0
              @notify.user_login(onlines_diff, @onlines, last_checked_at)
            end
          end
          @onlines_before = @onlines
        else
          if @status_before
            if @status_before != status
              @notify.server_down(name, body, status, last_checked_at)
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

