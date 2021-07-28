require_relative './serverinfo'

module Events
  class StandardEvent
    def initialize(**kwargs)
      @events = kwargs
    end
    private
    def _access_member(key)
      @events[key]
    end
  end
  
  class MinecraftServerEvent < StandardEvent
    def initialize(server:, last_checked_at:, infos: {}, **kwargs)
      super(
        server: server,
        last_checked_at: last_checked_at,
        infos: infos,
        **kwargs,
      )
    end
    def server
      _access_member(:server)
    end
    def last_checked_at
      _access_member(:last_checked_at)
    end
    def infos
      _access_member(:infos)
    end
  end
  
  class ServerUp < MinecraftServerEvent; end
  class ServerDown < MinecraftServerEvent; end
  
  class UserEvent < MinecraftServerEvent; end
  class UserLogined < UserEvent
    def initialize(server:, onlines_diff:, onlines:, last_checked_at:)
      super(
        server: server,
        onlines_diff: onlines_diff,
        onlines: onlines,
        last_checked_at: last_checked_at,
      )
    end
    def onlines_diff
      _access_member(:onlines_diff)
    end
    def onlines
      _access_member(:onlines)
    end
  end
end
