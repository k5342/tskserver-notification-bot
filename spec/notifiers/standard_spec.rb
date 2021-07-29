require_relative '../../notifiers/standard'

describe Notifier::StandardNotifier do
  let!(:notifier) do
    Notifier::StandardNotifier.new
  end
  it 'has #user_login and raise NotImplementedError' do
    expect{ notifier.user_login(nil) }.to raise_error(NotImplementedError)
  end
  it 'has #server_up and raise NotImplementedError' do
    expect{ notifier.server_up(nil) }.to raise_error(NotImplementedError)
  end
  it 'has #server_down and raise NotImplementedError' do
    expect{ notifier.server_down(nil) }.to raise_error(NotImplementedError)
  end
end
