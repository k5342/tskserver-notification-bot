require 'discordrb'

require_relative './standard'
require_relative '../events'

module Notifier
  class DiscordNotifier < AbstractNotifier
    def initialize(token:, client_id:, channel_id:)
      @bot = Discordrb::Bot.new(
        token: token,
        client_id: client_id,
      )
      @bot.run :async
      puts "bot invite URL: #{@bot.invite_url}"
      @client = Discord.new(@bot, channel_id)
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
end
