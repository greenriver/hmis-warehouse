###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::AutoExitJob, type: :model do
  # Probably other specs aren't cleaning up:
  before(:all) { cleanup_test_environment }

  let!(:ds1) { create(:hmis_data_source) }
  let!(:u1) { create :hmis_hud_user, data_source: ds1, user_email: 'test@example.com' }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }

  describe 'with residential projects' do
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 0 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:aec) { create :hmis_auto_exit_config, length_of_absence_days: 30 }

    it 'should exit correctly for a bed night' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      e2 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 200
      s2 = create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e2, user: u1, record_type: 200, date_provided: Date.today - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e2)
      expect(Hmis::Hud::Enrollment.exited).not_to include(e1)
      expect(e2.exit).to have_attributes(auto_exited: be_present, exit_date: s2.date_provided + 1.day, destination: 30)
      expect(e2.exit_assessment&.assessment_date).to eq(s2.date_provided + 1.day)
      expect(e2.exit_assessment&.data_collection_stage).to eq(3)
    end
  end

  describe 'with non-residential projects' do
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 6 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:aec) { create :hmis_auto_exit_config, length_of_absence_days: 30 }

    it 'should exit correctly for a service' do
      contact_date = Date.today - 31.days

      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: contact_date - 1.day
      s2 = create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: contact_date

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: s2.date_provided, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(have_attributes(assessment_date: s2.date_provided, data_collection_stage: 3))
      expect(e1.exit_assessment.form_processor.exit).to eq(e1.exit)
    end

    it 'should exit correctly for a custom service' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      cs1 = create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, date_provided: Date.today - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: cs1.date_provided, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(have_attributes(assessment_date: cs1.date_provided, data_collection_stage: 3))
    end

    it 'should exit correctly for a current living situation' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      cls1 = create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e1, user: u1, information_date: Date.today - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: cls1.information_date, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(have_attributes(assessment_date: cls1.information_date, data_collection_stage: 3))
    end

    it 'should exit correctly for an assessment' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      ca1 = create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1, assessment_date: Date.today - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: ca1.assessment_date, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(ca1, have_attributes(assessment_date: ca1.assessment_date, data_collection_stage: 3))
    end

    it 'should pick the latest exit date for all entities considered as contacts' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: Date.today - 33.days
      create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, date_provided: Date.today - 32.days
      cls1 = create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e1, user: u1, information_date: Date.today - 31.days
      ca1 = create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1, assessment_date: Date.today - 34.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: cls1.information_date, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(ca1, have_attributes(assessment_date: cls1.information_date, data_collection_stage: 3))
    end
  end

  it 'should throw error if length_of_absence_days is less than 30' do
    p1 = create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 6
    c1 = create :hmis_hud_client, data_source: ds1, user: u1

    # We want to set the length_of_absence_days to 29 to test logic in the job, but there is an AR validation on this too, so set it without validating
    aec = create :hmis_auto_exit_config, length_of_absence_days: 30
    aec.length_of_absence_days = 29
    aec.save!(validate: false)

    e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.today - 2.months
    create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, date_provided: Date.today - 31.days

    expect { Hmis::AutoExitJob.perform_now }.to raise_error(RuntimeError, 'Auto-exit config unusually low: 29')
  end
end
