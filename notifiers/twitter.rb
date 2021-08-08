require 'twitter'

require_relative './standard'
require_relative '../events'

module Notifier
  class Twitter < StandardNotifier
    def initialize(consumer_key:, consumer_secret:, access_token:, access_token_secret:)
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key        = consumer_key
        config.consumer_secret     = consumer_secret
        config.access_token        = access_token
        config.access_token_secret = access_token_secret
      end 
      @tweet = Tweet.new(@client)
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
end
