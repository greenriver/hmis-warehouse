###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::Reminders::ReminderGenerator, type: :model do
  include_context 'hmis base setup'
  include_context 'hmis service setup'
  let(:today) do
    Date.current
  end

  def reminders_for(_enrollment, topic:)
    project = p1
    Hmis::Reminders::ReminderGenerator.
      perform(project: project, enrollments: project.enrollments_including_wip).
      filter { |r| r.topic == topic }
  end

  describe 'with an enrollment due for annual assessment' do
    let(:enrollment) do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, entry_date: today - (1.year - 30.days)
    end
    it 'reminds about annual assessment' do
      expect(reminders_for(enrollment, topic: 'annual_assessment').size).to eq(1)
    end

    it 'reminds about annual assessment where period overlaps the new year' do
      travel_to Time.local(2023, 12, 6) do
        enrollment.update(entry_date: Time.local(2023, 1, 3))
        res = reminders_for(enrollment, topic: 'annual_assessment')
        expect(res.size).to eq(1)
        expect(res.first.due_date).to eq(Time.local(2024, 2, 2))
      end
    end

    it 'reminds about annual assessment where period overlaps the new year (multiple years ago)' do
      travel_to Time.local(2023, 12, 6) do
        enrollment.update(entry_date: Time.local(2020, 1, 3))
        res = reminders_for(enrollment, topic: 'annual_assessment')
        expect(res.size).to eq(1)
        expect(res.first.due_date).to eq(Time.local(2024, 2, 2))
      end
    end

    # Entry date: 1/15/2020
    # Expected due period: 12/15/2023-2/14/2024
    [
      Time.local(2023, 12, 17), # within first half of due period
      Time.local(2024, 1, 20), # within second half of due period
      Time.local(2024, 2, 30), # after due period (should still show up as overdue)
    ].each do |local_time|
      it "reminds about annual assessment where household entered in January (current date: #{local_time})" do
        travel_to local_time do
          enrollment.update(entry_date: Time.local(2020, 1, 15))
          res = reminders_for(enrollment, topic: 'annual_assessment')
          expect(res.size).to eq(1)
          expect(res.first.due_date).to eq(Time.local(2024, 2, 14)), local_time.inspect
        end
      end
    end

    # Entry date: 12/15/2020
    # Expected due period: 11/15/2023-1/14/2024
    [
      Time.local(2023, 11, 16), # within first half of due period
      Time.local(2024, 1, 6), # within second half of due period
      Time.local(2024, 1, 30), # after due period (should still show up as overdue)
    ].each do |local_time|
      it "reminds about annual assessment where household entered in December (current date: #{local_time})" do
        travel_to local_time do
          enrollment.update(entry_date: Time.local(2020, 12, 15))
          res = reminders_for(enrollment, topic: 'annual_assessment')
          expect(res.size).to eq(1)
          expect(res.first.due_date).to eq(Time.local(2024, 1, 14)), local_time.inspect
        end
      end
    end

    it 'does not remind if the next annual is due in the future (a.k.a. last annual period is >6mo ago)' do
      travel_to Time.local(2023, 12, 20) do
        enrollment.update(entry_date: Time.local(2022, 6, 10))
        # next upcoming due date is May 2024. No reminder because it's too far in the future.
        res = reminders_for(enrollment, topic: 'annual_assessment')
        expect(res).to be_empty
      end
    end

    describe 'with annual assessment completed' do
      before(:each) do
        create(:hmis_custom_assessment, data_collection_stage: 5, assessment_date: today, enrollment: enrollment, data_source: ds1)
      end
      it 'does not remind about annual assessment' do
        expect(reminders_for(enrollment, topic: 'annual_assessment').size).to eq(0)
      end
    end
  end

  describe 'with an enrollment not due for annual assessment' do
    let(:enrollment) do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, entry_date: today
    end
    it 'does not remind about annual assessment' do
      expect(reminders_for(enrollment, topic: 'annual_assessment').size).to eq(0)
    end
  end

  describe 'with an individual aging into adulthood after entry' do
    let(:enrollment) do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1, DOB: (today - (18.years + 1.day))
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, entry_date: today - 2.days
    end
    it 'reminds about an update assessment' do
      expect(reminders_for(enrollment, topic: 'aged_into_adulthood').size).to eq(1)
    end
    describe 'with update completed assessment completed' do
      before(:each) do
        create(:hmis_custom_assessment, data_collection_stage: 2, assessment_date: today, enrollment: enrollment, data_source: ds1)
      end
      it 'does not remind about update assessment' do
        expect(reminders_for(enrollment, topic: 'aged_into_adulthood').size).to eq(0)
      end
    end
  end

  describe 'with a client not yet aged into adulthood' do
    let(:enrollment) do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1, DOB: (today - (18.years - 1.day))
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, entry_date: today
    end
    it 'does not remind about update assessment' do
      expect(reminders_for(enrollment, topic: 'aged_into_adulthood').size).to eq(0)
    end
  end

  describe 'with a client aged to adulthood after enrollment' do
    let(:enrollment) do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1, DOB: (today - (18.years + 1.day))
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, entry_date: today
    end
    it 'does not remind about update assessment' do
      expect(reminders_for(enrollment, topic: 'aged_into_adulthood').size).to eq(0)
    end
  end

  describe 'with an enrollment' do
    let(:enrollment) do
      client = create :hmis_hud_client_complete, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, entry_date: today - 6.months
    end

    describe 'with no intake assessment' do
      it 'reminds about intake assessment' do
        expect(reminders_for(enrollment, topic: 'intake_incomplete').size).to eq(1)
      end
    end

    describe 'with an intake assessment in progress' do
      before(:each) do
        create(:hmis_wip_custom_assessment, data_collection_stage: 1, enrollment: enrollment, data_source: ds1)
      end
      it 'reminds about intake assessment' do
        expect(reminders_for(enrollment, topic: 'intake_incomplete').size).to eq(1)
      end
    end

    describe 'with an intake assessment completed' do
      before(:each) do
        create(:hmis_custom_assessment, data_collection_stage: 1, assessment_date: today, enrollment: enrollment, data_source: ds1)
      end
      it 'does not remind about intake assessment' do
        expect(reminders_for(enrollment, topic: 'intake_incomplete').size).to eq(0)
      end
    end

    it 'does not remind about exit assessment' do
      expect(reminders_for(enrollment, topic: 'exit_incomplete').size).to eq(0)
    end

    describe 'with an exit assessment in progress' do
      before(:each) do
        create(:hmis_wip_custom_assessment, data_collection_stage: 3, enrollment: enrollment, data_source: ds1)
      end
      it 'reminds about exit assessment' do
        expect(reminders_for(enrollment, topic: 'exit_incomplete').size).to eq(1)
      end
    end

    it 'does not remind about current-living-situation information' do
      expect(reminders_for(enrollment, topic: 'current_living_situation').size).to eq(0)
    end
    describe 'in a coordinated entry project' do
      before(:each) { p1.update!(ProjectType: 14) }

      describe 'due for current-living-situation information' do
        before(:each) do
          create(:hmis_current_living_situation, data_source: ds1, enrollment: enrollment, information_date: today - 91.days)
        end
        it 'reminds about current-living-situation information' do
          expect(reminders_for(enrollment, topic: 'current_living_situation').size).to eq(1)
        end
        describe 'with current-living-situation information completed' do
          before(:each) do
            create(:hmis_current_living_situation, data_source: ds1, enrollment: enrollment, information_date: today)
          end
          it 'does not remind about current-living-situation information' do
            expect(reminders_for(enrollment, topic: 'current_living_situation').size).to eq(0)
          end
        end
      end
    end
  end
end
