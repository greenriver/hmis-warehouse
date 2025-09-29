# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'delayed_job:prune', type: :task do
  include ActiveSupport::Testing::TimeHelpers

  let(:task_name) { 'delayed_job:prune' }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'delayed_job:prune' }
  end

  before do
    # Ensure a clean slate for each example and a fresh task invocation
    Delayed::Job.delete_all
    Rake::Task[task_name].reenable

    # Default envs for deterministic behavior in specs
    ENV['K8S_NAMESPACE'] = 'default'
    ENV['PRUNE_DJ_QUEUE'] = nil
    ENV['PRUNE_DJ_STALE_MINUTES'] = '1'
  end

  after do
    ENV.delete('PRUNE_DJ_ACTION')
    ENV.delete('PRUNE_DJ_QUEUE')
    ENV.delete('PRUNE_DJ_STALE_MINUTES')
    ENV.delete('K8S_NAMESPACE')
  end

  def stub_k8s_pods(pod_names)
    client = double('K8s::Client')
    api = double('K8s::Api')
    resource = double('K8s::ResourceClient')

    allow(K8s::Client).to receive(:in_cluster_config).and_return(client)
    allow(client).to receive(:api).with('v1').and_return(api)
    allow(api).to receive(:resource).with('pods', namespace: 'default').and_return(resource)

    pods = pod_names.map { |name| double('K8s::Resource', metadata: double('K8s::ResourceMeta', name: name)) }
    allow(resource).to receive(:list).and_return(pods)
  end

  it 'fails stale jobs when the locking pod is missing (default action)' do
    stub_k8s_pods([])
    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 2.minutes.ago,
        locked_by: 'delayed_job.0 host:dead-pod-123 pid:9',
      )

      expect(job.failed_at).to be_nil

      Rake::Task[task_name].invoke

      job.reload
      expect(job.failed_at).to be_present
      expect(job.last_error).to include('Pruned at', 'dead-pod-123')
    end
  end

  it 'unlocks stale jobs when action is unlock and pod is missing' do
    stub_k8s_pods([])
    ENV['PRUNE_DJ_ACTION'] = 'unlock'

    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 2.minutes.ago,
        locked_by: 'delayed_job.0 host:dead-pod-123 pid:9',
      )

      Rake::Task[task_name].invoke

      job.reload
      expect(job.locked_by).to be_nil
      expect(job.locked_at).to be_nil
      expect(job.run_at).to be_within(1.second).of(Time.current)
      expect(job.failed_at).to be_nil
    end
  end

  it 'skips jobs when the locking pod still exists' do
    stub_k8s_pods(['live-pod-1'])

    job = Delayed::Job.create!(
      handler: "--- {}\n",
      queue: 'default',
      run_at: Time.current,
      locked_at: 10.minutes.ago,
      locked_by: 'delayed_job.0 host:live-pod-1 pid:7',
    )

    Rake::Task[task_name].invoke

    job.reload
    expect(job.failed_at).to be_nil
    expect(job.locked_by).to include('host:live-pod-1')
  end

  it 'scopes by queue when PRUNE_DJ_QUEUE is set' do
    stub_k8s_pods([])
    ENV['PRUNE_DJ_QUEUE'] = 'default'

    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      default_job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 2.minutes.ago,
        locked_by: 'delayed_job.0 host:dead-pod-123 pid:9',
      )

      other_job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'other',
        run_at: Time.current,
        locked_at: 2.minutes.ago,
        locked_by: 'delayed_job.0 host:dead-pod-456 pid:10',
      )

      Rake::Task[task_name].invoke

      expect(default_job.reload.failed_at).to be_present
      expect(other_job.reload.failed_at).to be_nil
      expect(other_job.locked_by).to be_present
    end
  end

  it 'acts only on locks strictly older than the cutoff' do
    stub_k8s_pods([])

    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      stale_job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 61.seconds.ago,
        locked_by: 'delayed_job.0 host:dead-pod-1 pid:9',
      )

      fresh_job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 59.seconds.ago,
        locked_by: 'delayed_job.0 host:dead-pod-2 pid:9',
      )

      Rake::Task[task_name].invoke

      expect(stale_job.reload.failed_at).to be_present
      expect(fresh_job.reload.failed_at).to be_nil
      expect(fresh_job.locked_by).to be_present
    end
  end

  it 'skips jobs with nil locked_at' do
    stub_k8s_pods([])

    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: nil,
        locked_by: 'delayed_job.0 host:dead-pod-123 pid:9',
      )

      Rake::Task[task_name].invoke

      job.reload
      expect(job.failed_at).to be_nil
      expect(job.locked_by).to be_present
    end
  end

  it 'exits with error on unsupported action and makes no changes' do
    stub_k8s_pods([])
    ENV['PRUNE_DJ_ACTION'] = 'bogus'

    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 2.minutes.ago,
        locked_by: 'delayed_job.0 host:dead-pod-123 pid:9',
      )

      expect { Rake::Task[task_name].invoke }.to raise_error(SystemExit)

      job.reload
      expect(job.failed_at).to be_nil
      expect(job.locked_by).to be_present
    end
  end

  it 'prefers ENV vars over rake args for action' do
    stub_k8s_pods([])
    ENV['PRUNE_DJ_ACTION'] = 'unlock'

    travel_to(Time.zone.parse('2025-01-01 12:00:00 UTC')) do
      job = Delayed::Job.create!(
        handler: "--- {}\n",
        queue: 'default',
        run_at: Time.current,
        locked_at: 2.minutes.ago,
        locked_by: 'delayed_job.0 host:dead-pod-123 pid:9',
      )

      # Pass a conflicting rake arg; ENV should take precedence and unlock
      Rake::Task[task_name].invoke('fail', nil, nil)

      job.reload
      expect(job.locked_by).to be_nil
      expect(job.locked_at).to be_nil
      expect(job.failed_at).to be_nil
    end
  end
end
