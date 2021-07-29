module Notifier
  class StandardNotifier
    def user_login(event)
      raise NotImplementedError
    end
    
    def server_down(event)
      raise NotImplementedError
    end
    
    def server_up(event)
      raise NotImplementedError
    end
  end
end
