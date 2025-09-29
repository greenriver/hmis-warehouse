# frozen_string_literal: false

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
      enrollment = double('enrollment', id: 1, exit: nil)
      household = double('household', enrollments: [enrollment, enrollment]) # 2 enrollments
      households_scope = double('households_scope')

      allow(project).to receive(:households).and_return(households_scope)
      allow(households_scope).to receive_message_chain(:active, :not_in_progress, :preload).and_return([household])

      # Mock the date calculation and contact checking
      allow(job).to receive(:household_has_active_ce_referral?).and_return(false)
      allow(job).to receive(:get_most_recent_contact).and_return(enrollment)
      allow(Hmis::Hud::Enrollment).to receive(:contact_date_for_entity).and_return(60.days.ago.to_date)

      # Mock the auto_exit method to avoid actual database operations
      allow(job).to receive(:auto_exit)
      allow(Hmis::Hud::Base).to receive(:transaction).and_yield

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

  describe '#auto_exit method with += operations' do
    it 'calls method that contains += operations for date calculation' do
      # Test the += operations from lines 135, 137: exit_date += 1.day

      job = Hmis::AutoExitJob.new

      # Create test data
      enrollment = double(
        'enrollment',
        personal_id: 'PERSON123',
        enrollment_id: 'ENROLL123',
        data_source_id: 1,
        entry_date: Date.current,
      )

      # Test bed night service (record_type 200) - should add 1 day
      bed_night_service = double(
        'service',
        is_a?: true,
        record_type: 200,
      )
      allow(bed_night_service).to receive(:is_a?).with(Hmis::Hud::Service).and_return(true)

      project = double('project')
      allow(project).to receive(:allows_same_day_exit?).and_return(false)

      # Mock contact date calculation
      contact_date = Date.current
      allow(Hmis::Hud::Enrollment).to receive(:contact_date_for_entity).and_return(contact_date)

      # Mock user and record creation
      user = double('user', user_id: 'USER123')
      allow(Hmis::Hud::User).to receive(:system_user).and_return(user)
      allow(job).to receive(:system_user).and_return(user)

      exit_record = double('exit_record', invalid?: false)
      allow(Hmis::Hud::Exit).to receive(:new).and_return(exit_record)

      assessment = double('assessment')
      allow(Hmis::Hud::CustomAssessment).to receive(:new).and_return(assessment)
      allow(assessment).to receive(:build_form_processor)
      allow(assessment).to receive(:save!)

      allow(enrollment).to receive(:release_unit!)
      allow(enrollment).to receive(:close_referral!)

      # This will exercise the += operations for date calculation
      expect { job.send(:auto_exit, enrollment, bed_night_service, project: project) }.not_to raise_error

      # The method should have been called and the += operations executed
      expect(Hmis::Hud::Exit).to have_received(:new)
    end

    it 'handles same-day exit scenario with += operation' do
      # Test the += operation from line 137 when exit_date == enrollment.entry_date

      job = Hmis::AutoExitJob.new
      entry_date = Date.current

      enrollment = double(
        'enrollment',
        personal_id: 'PERSON456',
        enrollment_id: 'ENROLL456',
        data_source_id: 1,
        entry_date: entry_date,
      )

      # Mock a non-service contact (won't trigger first += operation)
      most_recent_contact = double('contact')
      allow(most_recent_contact).to receive(:is_a?).with(Hmis::Hud::Service).and_return(false)

      project = double('project')
      allow(project).to receive(:allows_same_day_exit?).and_return(false)

      # Contact date equals entry date - should trigger second += operation
      allow(Hmis::Hud::Enrollment).to receive(:contact_date_for_entity).and_return(entry_date)

      # Mock dependencies
      user = double('user', user_id: 'USER456')
      allow(Hmis::Hud::User).to receive(:system_user).and_return(user)
      allow(job).to receive(:system_user).and_return(user)

      exit_record = double('exit_record', invalid?: false)
      allow(Hmis::Hud::Exit).to receive(:new).and_return(exit_record)

      assessment = double('assessment')
      allow(Hmis::Hud::CustomAssessment).to receive(:new).and_return(assessment)
      allow(assessment).to receive(:build_form_processor)
      allow(assessment).to receive(:save!)

      allow(enrollment).to receive(:release_unit!)
      allow(enrollment).to receive(:close_referral!)

      # This will exercise the second += operation (exit_date += 1.day for same-day exit)
      expect { job.send(:auto_exit, enrollment, most_recent_contact, project: project) }.not_to raise_error

      expect(Hmis::Hud::Exit).to have_received(:new)
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
