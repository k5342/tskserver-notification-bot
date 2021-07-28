class ServerInfo
  attr_reader :name, :host, :website_url, :infos
  def initialize(name:, host:, website_url:, infos: {})
    @name = name
    @host = host
    @website_url = website_url
    @infos = infos.transform_keys(&:to_sym)
  end
end
