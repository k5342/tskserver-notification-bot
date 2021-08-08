require 'httpclient'

require_relative './notifiers/notifier'
require_relative './events'

class NotifyManager
  def initialize(heartbeat_url: nil)
    @notifiers = []
    @heartbeat_last_sent_at = -1
    @heartbeat_client = HTTPClient.new
    @heartbeat_url = heartbeat_url
  end
  
  def register(notifier)
    raise ArgumentError unless notifier.is_a?(Notifier::StandardNotifier)
    @notifiers << notifier
  end
  
  def fire_event(event)
    case event
    when Events::UserLogined
      @notifiers.each{|n| n.user_login(event) }
    when Events::ServerUp
      @notifiers.each{|n| n.server_up(event) }
    when Events::ServerDown
      @notifiers.each{|n| n.server_down(event) }
    else
      raise ArgumentError, 'Unknown event type'
    end
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

