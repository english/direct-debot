# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/direct_debot/system'

RSpec.describe DirectDebot::System do
  class DB
    def start
    end

    def stop
    end
  end

  class JobQueue
    attr_reader :my_db

    def start(db)
      @my_db = db
    end

    def stop
    end
  end

  class Mailer
    def start
    end

    def stop
    end
  end

  it 'starts components in order' do
    db        = DB.new
    job_queue = JobQueue.new
    mailer    = Mailer.new

    system = described_class.new(job_queue: [job_queue, :db], mailer: mailer, db: db)

    expect(db).to receive(:start).ordered.and_call_original
    expect(job_queue).to receive(:start).ordered.and_call_original
    expect(mailer).to receive(:start).ordered.and_call_original

    expect(system.fetch(:db)).to be_a(DB)

    system.start
  end

  it 'provides dependencies' do
    db        = DB.new
    job_queue = JobQueue.new
    mailer    = Mailer.new

    system = described_class.new(job_queue: [job_queue, :db], mailer: mailer, db: db)
    system.start

    expect(job_queue.my_db).to be(db)
  end

  it 'stops components in reverse order' do
    db        = DB.new
    job_queue = JobQueue.new
    mailer    = Mailer.new

    system = described_class.new(job_queue: [job_queue, :db], mailer: mailer, db: db)

    expect(mailer).to receive(:stop).ordered.and_call_original
    expect(job_queue).to receive(:stop).ordered.and_call_original
    expect(db).to receive(:stop).ordered.and_call_original

    system.stop
  end
end
