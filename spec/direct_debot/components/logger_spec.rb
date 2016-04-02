require_relative '../../../lib/direct_debot/components/logger'

RSpec.describe DirectDebot::Components::Logger do
  let(:tempfile) { Tempfile.new('log') }

  subject { described_class.new(tempfile.path) }

  around do |example|
    subject.start
    example.call
    subject.stop
  end

  it 'logs to the given path at all levels' do
    subject.info('info message')
    subject.debug('debug message')
    subject.error('error message')

    first, second, third = File.readlines(tempfile.path)

    expect(first).to  match(/^I, \[.+\]  INFO -- direct-debot: info message$/)
    expect(second).to match(/^D, \[.+\] DEBUG -- direct-debot: debug message$/)
    expect(third).to  match(/^E, \[.+\] ERROR -- direct-debot: error message$/)
  end
end
