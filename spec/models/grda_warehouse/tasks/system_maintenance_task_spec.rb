# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::SystemMaintenanceTask, type: :model do
  let(:task) { create(:system_maintenance_task) }

  describe 'associations' do
    it { is_expected.to have_many(:system_maintenance_task_runs) }
  end

  describe '#threshold_exceeded?' do
    let(:task) { create(:system_maintenance_task, completion_alert_minutes: 60) }

    context 'when there are no completed runs' do
      it 'returns true' do
        expect(task.threshold_exceeded?).to be true
      end
    end

    context 'when there are recent completed runs within threshold' do
      before do
        create(:system_maintenance_task_run,
               system_maintenance_task: task,
               started_at: 30.minutes.ago,
               completed_at: 25.minutes.ago)
      end

      it 'returns false' do
        expect(task.threshold_exceeded?).to be false
      end
    end

    context 'when the most recent completed run is outside threshold' do
      before do
        create(:system_maintenance_task_run,
               system_maintenance_task: task,
               started_at: 90.minutes.ago,
               completed_at: 85.minutes.ago)
      end

      it 'returns true' do
        expect(task.threshold_exceeded?).to be true
      end
    end

    context 'when there are incomplete runs within threshold' do
      before do
        create(:system_maintenance_task_run,
               system_maintenance_task: task,
               started_at: 30.minutes.ago,
               completed_at: nil)
      end

      it 'returns true' do
        expect(task.threshold_exceeded?).to be true
      end
    end
  end

  describe '#process_alerts' do
    let(:task) { create(:system_maintenance_task, name: 'Test Task', completion_alert_minutes: 60) }

    before do
      allow(Sentry).to receive(:capture_message)
    end

    context 'when threshold is not exceeded' do
      before do
        allow(task).to receive(:threshold_exceeded?).and_return(false)
      end

      it 'does not send alerts' do
        task.process_alerts

        expect(Sentry).not_to have_received(:capture_message)
        expect(task.reload.alert_sent_at).to be_nil
      end
    end

    context 'when threshold is exceeded and no alert has been sent' do
      before do
        allow(task).to receive(:threshold_exceeded?).and_return(true)
      end

      it 'sends alert to Sentry' do
        freeze_time do
          task.process_alerts

          expect(Sentry).to have_received(:capture_message).with(/Missing scheduled execution.*Task has not completed successfully/)
        end
      end

      it 'updates alert_sent_at timestamp' do
        freeze_time do
          task.process_alerts
          expect(task.reload.alert_sent_at).to eq(Time.current)
        end
      end
    end

    context 'when threshold is exceeded but alert has already been sent' do
      before do
        allow(task).to receive(:threshold_exceeded?).and_return(true)
        task.update!(alert_sent_at: 1.hour.ago)
      end

      it 'does not send another alert' do
        task.process_alerts

        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end
end
