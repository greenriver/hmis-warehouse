# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AutoExitJob, type: :job do
  describe '#_perform method with += operations' do
    it 'calls method that contains += operations for count accumulation' do
      # Test the += operation from line 83: auto_exit_count += household.enrollments.size

      job = Hmis::AutoExitJob.new

      # Mock the auto exit config
      config = double('config', length_of_absence_days: 45)
      allow(Hmis::ProjectAutoExitConfig).to receive(:detect_best_config_for_project).and_return(config)

      # Mock project and household data
      project = double('project', id: 1, households: double('households'))
      allow(Hmis::Hud::Project).to receive(:hmis).and_return([project])

      # Mock household with enrollments
      enrollment = double('enrollment', id: 1, exit: nil, entry_date: 60.days.ago.to_date)
      allow(enrollment).to receive(:is_a?).with(Hmis::Hud::Enrollment).and_return(true)
      allow(enrollment).to receive(:is_a?).with(Hmis::Hud::Service).and_return(false)
      allow(enrollment).to receive(:project).and_return(double('project', allows_same_day_exit?: true))
      household = double('household', enrollments: [enrollment, enrollment]) # 2 enrollments
      households_scope = double('households_scope')

      allow(project).to receive(:households).and_return(households_scope)
      allow(households_scope).to receive_message_chain(:active, :not_in_progress, :preload).and_return([household])

      # Mock the date calculation and contact checking
      allow(job).to receive(:household_has_active_ce_referral?).and_return(false)
      allow(job).to receive(:get_most_recent_contact).and_return(enrollment)
      allow(Hmis::Hud::Enrollment).to receive(:contact_date_for_entity).and_return(60.days.ago.to_date)

      # Mock the shared PerformAutoExit service to avoid actual database operations
      allow(Hmis::PerformAutoExit).to receive(:call)

      # Mock the notifier
      allow(job).to receive(:setup_notifier)
      notifier = double('notifier')
      allow(notifier).to receive(:ping)
      job.instance_variable_set(:@notifier, notifier)

      # Call the method that contains the += operation
      expect { job.send(:_perform) }.not_to raise_error

      # The += operation should have accumulated the enrollment count
      expect(notifier).to have_received(:ping).with(/Auto-exited 2 Enrollments/)
    end
  end

  describe '#compute_exit_date method with += operations' do
    it 'adds 1 day when most recent contact was a bed night service (record_type 200)' do
      # Test the += operation: exit_date += 1.day for bed night
      job = Hmis::AutoExitJob.new
      contact_date = Date.current
      enrollment = double('enrollment', entry_date: Date.current)
      project = double('project', allows_same_day_exit?: true)
      allow(enrollment).to receive(:project).and_return(project)

      bed_night_service = double('service', record_type: 200)
      allow(bed_night_service).to receive(:is_a?).with(Hmis::Hud::Service).and_return(true)
      allow(bed_night_service).to receive(:is_a?).with(Hmis::Hud::Enrollment).and_return(false)
      allow(bed_night_service).to receive(:enrollment).and_return(enrollment)
      allow(Hmis::Hud::Enrollment).to receive(:contact_date_for_entity).and_return(contact_date)

      exit_date = job.send(:compute_exit_date, bed_night_service)

      expect(exit_date).to eq(contact_date + 1.day)
    end

    it 'adds 1 day for same-day exit when project does not allow same-day exit' do
      # Test the += operation when exit_date == enrollment.entry_date
      job = Hmis::AutoExitJob.new
      entry_date = Date.current
      enrollment = double('enrollment', entry_date: entry_date)
      allow(enrollment).to receive(:is_a?).with(Hmis::Hud::Service).and_return(false)
      allow(enrollment).to receive(:is_a?).with(Hmis::Hud::Enrollment).and_return(true)
      project = double('project', allows_same_day_exit?: false)
      allow(enrollment).to receive(:project).and_return(project)

      allow(Hmis::Hud::Enrollment).to receive(:contact_date_for_entity).and_return(entry_date)

      exit_date = job.send(:compute_exit_date, enrollment)

      expect(exit_date).to eq(entry_date + 1.day)
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises perform method that contains mutation operations' do
      job = Hmis::AutoExitJob.new

      # Mock the enabled check
      allow(Hmis::ProjectAutoExitConfig).to receive(:exists?).and_return(true)

      # Mock the _perform method to avoid complex setup
      allow(job).to receive(:_perform)

      # Should call _perform which contains the += operations
      expect { job.perform }.not_to raise_error
      expect(job).to have_received(:_perform)
    end

    it 'creates new instance without error' do
      job = Hmis::AutoExitJob.new

      expect(job).to be_a(Hmis::AutoExitJob)
    end
  end
end
