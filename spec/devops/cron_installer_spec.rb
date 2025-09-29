# frozen_string_literal: true

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

  # Regression tests for string mutations during frozen string literal conversion
  describe '#get_command (string mutations)' do
    let(:subject) { CronInstaller.new }

    context 'with RAILS_ENV removal (sub!)' do
      it 'removes RAILS_ENV prefix from command' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app && RAILS_ENV=production bundle exec rake some:task'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'some:task'])
      end

      it 'handles multiple RAILS_ENV formats' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app && RAILS_ENV=staging bundle exec rake other:task'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'other:task'])
      end

      it 'handles commands without RAILS_ENV prefix' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app && bundle exec rake clean:task'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'clean:task'])
      end
    end

    context 'with whitespace stripping (strip!)' do
      it 'strips leading and trailing whitespace' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app &&    bundle exec rake task:name   '"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'task:name'])
      end

      it 'handles commands with only leading whitespace' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app &&     bundle exec rake task:clean'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'task:clean'])
      end

      it 'handles commands with only trailing whitespace' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app && bundle exec rake task:build     '"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'task:build'])
      end
    end

    context 'with both mutations combined' do
      it 'removes RAILS_ENV and strips whitespace together' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app &&   RAILS_ENV=production   bundle exec rake complex:task   '"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'complex:task'])
      end

      it 'handles complex commands with multiple components' do
        line = "0 2 * * * /bin/bash -l -c 'cd /app && RAILS_ENV=staging bundle exec rake grda_warehouse:daily --silent ##interruptable=false##'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['bundle', 'exec', 'rake', 'grda_warehouse:daily', '--silent', '##interruptable=false##'])
      end
    end

    context 'edge cases' do
      it 'handles minimal command structure' do
        line = "0 * * * * /bin/bash -l -c 'cd /app && rake task'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['rake', 'task'])
      end

      it 'raises error for invalid cron line without bash command' do
        line = '0 * * * * invalid_line_format'
        expect { subject.send(:get_command, line) }.to raise_error('invalid cron line')
      end

      it 'handles command without && separator by taking full command' do
        line = "0 * * * * /bin/bash -l -c 'cd /app'"
        result = subject.send(:get_command, line)
        expect(result).to eq(['cd', '/app'])
      end

      it 'handles empty command after && separator' do
        line = "0 * * * * /bin/bash -l -c 'cd /app &&   '"
        result = subject.send(:get_command, line)
        expect(result).to eq([])
      end
    end
  end
end
