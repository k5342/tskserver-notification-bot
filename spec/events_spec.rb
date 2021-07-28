require_relative '../events'
require_relative '../serverinfo'

def return_dummyserver_common
  ServerInfo.new(
    name: 'dummyserver',
    host: 'example.com',
    website_url: 'https://example.com/',
    infos: {
      version: {
        name: 'Paper 1.17.1',
        protocol: 756,
      }
    }
  )
end

describe Events::UserLogined do
  let(:dummyserver) do
    return_dummyserver_common
  end
  
  context 'with wrong arguments' do
    it 'should raise an exception' do
      expect{ Events::UserLogined.new }.to raise_error(ArgumentError)
    end
  end
  context 'with valid arguments' do
    let(:kwargs) do
      {
        server: dummyserver, 
        onlines_diff: ['playerA'],
        onlines: ['playerA', 'playerB', 'playerC'],
        last_checked_at: Time.now,
      }
    end
    subject(:event) do
      Events::UserLogined.new(
        server: kwargs[:dummyserver],
        onlines_diff: kwargs[:onlines_diff],
        onlines: kwargs[:onlines],
        last_checked_at: kwargs[:last_checked_at],
      )
    end
    it 'should return an instance' do
      expect(event).to be_a(Events::UserLogined)
      expect(event).to be_kind_of(Events::UserEvent)
      expect(event).to be_kind_of(Events::MinecraftServerEvent)
      expect(event).to be_kind_of(Events::StandardEvent)
      expect(event.server).to eq(kwargs[:dummyserver])
      expect(event.onlines_diff).to eq(kwargs[:onlines_diff])
      expect(event.onlines).to eq(kwargs[:onlines])
      expect(event.last_checked_at).to eq(kwargs[:last_checked_at])
    end
  end
end

describe Events::ServerUp do
  let(:dummyserver) do
    return_dummyserver_common
  end
  
  context 'with wrong arguments' do
    it 'should raise an exception' do
      expect{ Events::ServerUp.new }.to raise_error(ArgumentError)
    end
  end
  context 'with valid arguments' do
    let(:kwargs) do
      {
        server: dummyserver, 
        last_checked_at: Time.now,
      }
    end
    subject(:event) do
      Events::ServerUp.new(
        server: kwargs[:dummyserver],
        last_checked_at: kwargs[:last_checked_at],
      )
    end
    it 'should return an instance' do
      expect(event).to be_a(Events::ServerUp)
      expect(event).to be_kind_of(Events::MinecraftServerEvent)
      expect(event).to be_kind_of(Events::StandardEvent)
      expect(event.server).to eq(kwargs[:dummyserver])
      expect(event.last_checked_at).to eq(kwargs[:last_checked_at])
    end
  end
end

describe Events::ServerDown do
  let(:dummyserver) do
    return_dummyserver_common
  end
  
  context 'with wrong arguments' do
    it 'should raise an exception' do
      expect{ Events::ServerDown.new }.to raise_error(ArgumentError)
    end
  end
  context 'with valid arguments' do
    let(:kwargs) do
      {
        server: dummyserver, 
        last_checked_at: Time.now,
        infos: {
          error: 'Errno::EHOSTUNREACH', detail: 'No route to host'
        }
      }
    end
    subject(:event) do
      Events::ServerDown.new(
        server: kwargs[:dummyserver],
        last_checked_at: kwargs[:last_checked_at],
        infos: kwargs[:infos],
      )
    end
    it 'should return an instance' do
      expect(event).to be_a(Events::ServerDown)
      expect(event).to be_kind_of(Events::MinecraftServerEvent)
      expect(event).to be_kind_of(Events::StandardEvent)
      expect(event.server).to eq(kwargs[:dummyserver])
      expect(event.last_checked_at).to eq(kwargs[:last_checked_at])
      expect(event.infos).to eq(kwargs[:infos])
    end
  end
end
