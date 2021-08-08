require_relative '../notifymanager'

describe NotifyManager do
  let!(:notifymanager) do
    NotifyManager.new(
      heartbeat_url: 'HEARTBEAT_URL',
    )
  end
  it 'can be initialized with arguments' do
    expect(notifymanager).to be_a(NotifyManager)
  end
  it 'can fire server_up event via a notifier' do
    notifier = Notifier::StandardNotifier.new
    event = Events::ServerUp.new(
      server: 'SERVER_NAME',
      last_checked_at: Time.now,
    )
    allow(notifier).to receive(:server_up)
    notifymanager.register(notifier)
    notifymanager.fire_event(event)
    expect(notifier).to have_received(:server_up).with(event).once
  end
  it 'can fire server_down event via a notifier' do
    notifier = Notifier::StandardNotifier.new
    event = Events::ServerDown.new(
      server: 'SERVER_NAME',
      last_checked_at: Time.now,
    )
    allow(notifier).to receive(:server_down)
    notifymanager.register(notifier)
    notifymanager.fire_event(event)
    expect(notifier).to have_received(:server_down).with(event).once
  end
  it 'can fire user_login event via a notifier' do
    notifier = Notifier::StandardNotifier.new
    event = Events::UserLogined.new(
      server: 'SERVER_NAME',
      last_checked_at: Time.now,
      onlines_diff: ['LOGINED_USER'],
      onlines: 1,
    )
    allow(notifier).to receive(:user_login)
    notifymanager.register(notifier)
    notifymanager.fire_event(event)
    expect(notifier).to have_received(:user_login).with(event).once
  end
end
