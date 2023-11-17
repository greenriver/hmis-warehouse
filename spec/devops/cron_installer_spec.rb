require 'rails_helper'

require_relative '../../config/deploy/docker/lib/cron_installer'

RSpec.describe CronInstaller, type: :model do
  let(:subject) { CronInstaller.new }

  it 'adds jitter to the minute a task should run' do
    plain = []
    with_jitter = []

    subject.send(:each_cron_entry, add_jitter: false) do |cron_expression, _|
      plain << cron_expression
    end

    subject.send(:each_cron_entry) do |cron_expression, _|
      with_jitter << cron_expression
    end

    ap(plain.zip(with_jitter)) if ENV['SEE_JITTER'] == 'true'

    matches = 0
    plain.zip(with_jitter).each do |plain_expression, jittered_expression|
      plain_minute = plain_expression.match(/cron\((\d+)/)[1].to_i
      jittered_minute = jittered_expression.match(/cron\((\d+)/)[1].to_i

      expect(plain_minute).to be_within(CronInstaller::AMOUNT_OF_JITTER_IN_MINUTES).of(jittered_minute)
      expect(plain_minute).to be < 60
      expect(plain_minute).to be >= 0
      expect(jittered_minute).to be < 60
      expect(jittered_minute).to be >= 0

      matches += 1 if plain_minute == jittered_minute
    end

    expect(matches).to be < (plain.length - 2)
  end
end
