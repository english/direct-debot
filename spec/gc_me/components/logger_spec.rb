require_relative '../../../lib/gc_me/components/logger'

RSpec.describe GCMe::Components::Logger do
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

    expect(first).to  match(/^I, \[.+\]  INFO -- gc-me: info message$/)
    expect(second).to match(/^D, \[.+\] DEBUG -- gc-me: debug message$/)
    expect(third).to  match(/^E, \[.+\] ERROR -- gc-me: error message$/)
  end
end
