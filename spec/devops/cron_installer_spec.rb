###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/deploy/cron_installer'

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
      plain_minute = plain_expression.match(/^(\d+)/)[1].to_i
      jittered_minute = jittered_expression.match(/^(\d+)/)[1].to_i

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
      let(:subject) { CronInstaller.new }
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
        Cronjob.clear_defunct!([])
        create_cronjob
        expect(cronjob.send(:cron_list).length).to eq(1)
        Cronjob.clear_defunct!([])
        expect(cronjob.send(:cron_list).length).to eq(0)
      end

    else
      it 'is not normally tested in CI because setup is too involved' do
      end
    end
  end

  describe 'installing cronjobs without deleting retained Jobs' do
    let(:crons) { double('crons') }
    let(:template) do
      <<~YAML
        kind: CronJob
        metadata:
          name: <%= jobname %>
          labels:
            cron-source: rails
          annotations:
            description: <%= description %>
        spec:
          schedule: "<%= schedule_expression %>"
      YAML
    end
    let(:cronjob) { Cronjob.new(description: 'rake some:task', schedule_expression: '5 * * * *', command: ['rake', 'some:task']) }

    before do
      allow(cronjob).to receive(:crons).and_return(crons)
      allow(cronjob).to receive(:configmap).and_return(double(data: { 'cronjob.yaml' => template }))
    end

    it 'creates a cronjob and VPA that are not in the cluster yet' do
      expect(crons).to receive(:create_resource)
      expect(crons).not_to receive(:json_patch)
      expect(cronjob).to receive(:create_vpa!)

      cronjob.run!(existing_crons: Set.new, existing_vpas: Set.new)
    end

    it 'patches an existing cronjob in place instead of recreating it' do
      expect(crons).not_to receive(:create_resource)
      expect(crons).to receive(:json_patch) do |name, ops|
        expect(name).to eq(cronjob.jobname)
        expect(ops).to include({ op: 'replace', path: '/spec', value: { 'schedule' => '5 * * * *' } })
      end
      expect(crons).not_to receive(:delete_resource)
      expect(cronjob).to receive(:update_vpa!)

      cronjob.run!(existing_crons: Set[cronjob.jobname], existing_vpas: Set["cronjob-#{cronjob.jobname}"])
    end

    it 'deletes only cronjobs that are no longer scheduled' do
      kept = K8s::Resource.new(metadata: { name: 'kept', namespace: 'ns' })
      defunct = K8s::Resource.new(metadata: { name: 'defunct', namespace: 'ns' })
      allow(cronjob).to receive(:cron_list).and_return([kept, defunct])

      expect(crons).to receive(:delete_resource).with(defunct)
      expect(crons).not_to receive(:delete_resource).with(kept)

      cronjob.clear_defunct!(['kept'])
    end

    it 'lists existing resources once and deletes only defunct cronjobs' do
      existing_crons = Set['a-task']
      existing_vpas = Set['cronjob-a-task']
      allow(Cronjob).to receive(:existing_cron_names).and_return(existing_crons)
      allow(Cronjob).to receive(:existing_vpa_names).and_return(existing_vpas)
      installer = CronInstaller.new
      allow(installer).to receive(:each_cron_entry).
        and_yield('5 * * * *', ['rake', 'a:task', '##interruptable=true##']).
        and_yield('6 * * * *', ['rake', 'b:task', '##interruptable=false##'])
      run_args = []
      allow_any_instance_of(Cronjob).to receive(:run!) { |_cronjob, **kwargs| run_args << kwargs }
      allow(Cronjob).to receive(:clear_defunct_vpas!)

      expect(Cronjob).to receive(:clear_defunct!).with(['a-task', 'b-task'])

      installer.run!

      expect(Cronjob).to have_received(:existing_cron_names).once
      expect(run_args).to eq([{ existing_crons: existing_crons, existing_vpas: existing_vpas }] * 2)
    end

    it 'refuses two schedule entries that map to the same cronjob name' do
      allow(Cronjob).to receive(:existing_cron_names).and_return(Set.new)
      allow(Cronjob).to receive(:existing_vpa_names).and_return(Set.new)
      installer = CronInstaller.new
      allow(installer).to receive(:each_cron_entry).
        and_yield('5 * * * *', ['rake', 'a:task', '##interruptable=true##']).
        and_yield('6 * * * *', ['rake', 'a:task', '##interruptable=true##'])
      allow_any_instance_of(Cronjob).to receive(:run!)

      expect(Cronjob).not_to receive(:clear_defunct!)
      expect { installer.run! }.to raise_error(/both map to cronjob name/)
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
