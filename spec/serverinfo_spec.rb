require_relative '../serverinfo'

describe ServerInfo do
  context 'with wrong arguments' do
    it 'should raise an exception' do
      expect{ ServerInfo.new }.to raise_error(ArgumentError)
    end
  end
  context 'with valid arguments' do
    let(:kwargs) do
      {
        name: 'dummyserver',
        host: 'example.com',
        website_url: 'https://example.com/',
        infos: {
          "description": {
            "text": "A Minecraft Server!"
          },
          "players": {
            "max": 20,
            "online": 0
          },
          "version": {
            "name": "paper 1.17.1",
            "protocol": 756,
          }
        }
      }
    end
    subject(:server) do
      ServerInfo.new(
        name: kwargs[:name],
        host: kwargs[:host],
        website_url: kwargs[:website_url],
        infos: kwargs[:infos],
      )
    end
    it 'should return an instance' do
      expect(server).to be_a(ServerInfo)
      expect(server.name).to eq(kwargs[:name])
      expect(server.host).to eq(kwargs[:host])
      expect(server.website_url).to eq(kwargs[:website_url])
      expect(server.infos).to eq(kwargs[:infos])
    end
    
    describe '#infos' do
      it 'should be accessible as a symbol' do
        expect(server.infos[:description]).to eq(kwargs[:infos][:description])
        expect(server.infos[:players]).to eq(kwargs[:infos][:players])
        expect(server.infos[:version]).to eq(kwargs[:infos][:version])
      end
    end
  end
end
