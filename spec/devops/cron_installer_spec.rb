require 'rails_helper'

require_relative '../../config/deploy/docker/lib/cron_installer'

RSpec.describe CronInstaller, type: :model do
  let(:subject) { CronInstaller.new }

  it 'adds jitter to the minute a task should run' do
    plain = []
    with_jitter = []
    subject.cluster_type = :ecs

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

  context 'EKS' do
    if ENV['KUBE_CONFIG_PATH'].present?
      let(:subject) { CronInstaller.new(:eks) }
      let(:cronjob) { Cronjob.new(description: 'nothing', command: 'sleep 3', schedule_expression: '5 * * * *') }

      def create_cronjob
        manifest = YAML.load_file('spec/devops/cronjob.yaml')
        crons = cronjob.send(:crons)
        cronjob_manifest = K8s::Resource.new(manifest)
        crons.create_resource(cronjob_manifest)
      end

      it 'has a smoketest' do
        subject.run!
      end

      it 'deletes cronjobs' do
        Cronjob.clear!
        create_cronjob
        expect(cronjob.send(:cron_list).length).to eq(1)
        Cronjob.clear!
        expect(cronjob.send(:cron_list).length).to eq(0)
      end

    else
      it 'is not normally tested in CI because setup is too involved' do
      end
    end
  end
end
