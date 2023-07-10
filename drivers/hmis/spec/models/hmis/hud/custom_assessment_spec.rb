###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::CustomAssessment, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'in progress assessments' do
    let!(:assessment) { create(:hmis_wip_custom_assessment) }

    it 'cleans up dependent wip after destroy' do
      assessment.reload
      expect(assessment.wip).to be_present

      assessment.destroy
      assessment.reload
      expect(assessment.wip).not_to be_present
      expect(assessment.form_processor).not_to be_present
    end
  end

  describe 'submitted assessments' do
    let!(:assessment) { create(:hmis_custom_assessment) }

    before(:each) do
      assessment.save_not_in_progress
    end

    it 'preserve shared data after destroy' do
      assessment.destroy
      assessment.reload

      [
        :enrollment,
        :client,
        :user,
      ].each do |assoc|
        expect(assessment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end
    end
  end

  describe 'custom assessment validator' do
    include_context 'hmis base setup'
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_ho_h: 1 }
    let!(:e1_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e1, client: e1.client }
    let!(:assessment) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e1) }

    def apply_assessment_date(date)
      assessment.update(assessment_date: date)
      assessment.enrollment.update(entry_date: date) if assessment.intake?
      assessment.enrollment.exit.update(exit_date: date) if assessment.exit?
    end

    [:INTAKE, :UPDATE, :ANNUAL, :EXIT].each do |role|
      before(:each) do
        assessment.update(data_collection_stage: Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[role])
        e1.update(entry_date: 2.weeks.ago)
        e1_exit.update(exit_date: 1.week.ago)
      end

      it "should error if assessment date is missing (#{role})" do
        apply_assessment_date(nil)
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment).map(&:to_h)
        expect(validations).to match([a_hash_including(severity: :error, type: :required)])
      end

      it "should succeed if assessment date is the same as entry date (#{role})" do
        apply_assessment_date(e1.entry_date)
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment).map(&:to_h)
        expect(validations).to be_empty
      end

      it "should maybe error if assessment date is before entry date (#{role})" do
        apply_assessment_date(e1.entry_date - 1.day)
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment).map(&:to_h)
        if assessment.intake?
          expect(validations).to be_empty
        else
          expect(validations).to match([a_hash_including(severity: :error, message: Hmis::Hud::Validators::BaseValidator.before_entry_message(e1.entry_date))])
        end
      end

      it "should maybe error if assessment date is after exit date (#{role})" do
        apply_assessment_date(e1_exit.exit_date + 1.day)
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment).map(&:to_h)
        if assessment.exit?
          expect(validations).to be_empty
        else
          expect(validations).to match([a_hash_including(severity: :error, message: Hmis::Hud::Validators::BaseValidator.after_exit_message(e1_exit.exit_date))])
        end
      end
    end

    describe 'for household exits' do
      let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_ho_h: 2, household_id: e1.household_id }
      let!(:e2_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e2, client: e2.client }
      let!(:assessment2) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e2) }
      before(:each) do
        assessment.update(data_collection_stage: Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[:EXIT])
        assessment2.update(data_collection_stage: Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[:EXIT])
        e1.update(entry_date: 2.weeks.ago)
        e2.update(entry_date: 2.weeks.ago)
        e1_exit.update(exit_date: 1.week.ago)
        e2_exit.update(exit_date: 1.week.ago)
      end

      it 'should warn if HoH exit date is before other members (persisted)' do
        apply_assessment_date(1.week.ago) # HoH exits 1 week ago
        assessment2.update(assessment_date: 3.days.ago) # Other member exits 3 days ago
        assessment2.enrollment.exit.update(exit_date: 3.days.ago)

        # Validate HoH
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment).map(&:to_h)
        expect(validations).to match([a_hash_including(severity: :warning, message: Hmis::Hud::Validators::ExitValidator.hoh_exits_before_others)])

        # Validate other member
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment2).map(&:to_h)
        expect(validations).to match([a_hash_including(severity: :warning, message: Hmis::Hud::Validators::ExitValidator.member_exits_after_hoh(e1.exit_date))])
      end

      it 'should warn if HoH exit date is before other members (unpersisted)' do
        hoh_exit_date = 1.week.ago
        other_exit_date = 3.days.ago
        # Assign in all the places it is accessed..
        assessment.assign_attributes(assessment_date: hoh_exit_date)
        assessment.enrollment.exit.assign_attributes(exit_date: hoh_exit_date)
        e1.exit.assign_attributes(exit_date: hoh_exit_date)
        assessment2.assign_attributes(assessment_date: other_exit_date)
        assessment2.enrollment.exit.assign_attributes(exit_date: other_exit_date)
        e2.exit.assign_attributes(exit_date: other_exit_date)

        # Validate HoH
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment, household_members: [e1, e2]).map(&:to_h)
        expect(validations).to match([a_hash_including(severity: :warning, message: Hmis::Hud::Validators::ExitValidator.hoh_exits_before_others)])

        # Validate other member
        validations = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment2, household_members: [e1, e2]).map(&:to_h)
        expect(validations).to match([a_hash_including(severity: :warning, message: Hmis::Hud::Validators::ExitValidator.member_exits_after_hoh(e1.exit_date))])
      end
    end
  end

  describe 'grouping related assessments' do
    include_context 'hmis base setup'
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, relationship_to_ho_h: 1 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, household_id: e1.household_id, relationship_to_ho_h: 8 }
    let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, household_id: e1.household_id, relationship_to_ho_h: 8 }

    it 'groups intake assessments, including WIP assessments' do
      a1 = create(:hmis_custom_assessment, data_collection_stage: 1, data_source: ds1, enrollment: e1)
      a2 = create(:hmis_wip_custom_assessment, data_collection_stage: 1, data_source: ds1, enrollment: e2)
      create(:hmis_custom_assessment, data_collection_stage: 3, data_source: ds1, enrollment: e3) # exit

      grouped = Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: [e1, e2, e3],
        assessment_role: :INTAKE,
        threshold: 1.day,
        assessment_id: nil,
      )
      expect(grouped).to include(a1, a2)
    end

    it 'groups intake assessments on WIP enrollments' do
      e1.save_in_progress
      a1 = create(:hmis_wip_custom_assessment, data_collection_stage: 1, data_source: ds1, enrollment: e1)
      a2 = create(:hmis_custom_assessment, data_collection_stage: 1, data_source: ds1, enrollment: e2)

      grouped = Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: [e1, e2, e3],
        assessment_role: :INTAKE,
        threshold: 1.day,
        assessment_id: nil,
      )
      expect(grouped).to include(a1, a2)
    end

    it 'groups annual assessments by date' do
      e1.save_in_progress
      e1_a1 = create(:hmis_custom_assessment, assessment_date: 2.years.ago, data_collection_stage: 5, data_source: ds1, enrollment: e1)

      _e2_a1 = create(:hmis_wip_custom_assessment, assessment_date: 6.months.ago, data_collection_stage: 5, data_source: ds1, enrollment: e1)
      e2_a2 = create(:hmis_wip_custom_assessment, assessment_date: 3.months.ago, data_collection_stage: 5, data_source: ds1, enrollment: e1)

      e3_a1 = create(:hmis_custom_assessment, assessment_date: 1.month.ago, data_collection_stage: 5, data_source: ds1, enrollment: e1)
      e3_a2 = create(:hmis_custom_assessment, assessment_date: 3.months.ago, data_collection_stage: 5, data_source: ds1, enrollment: e1)

      # no source assessments, include past 3 months
      grouped = Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: [e1, e2, e3],
        assessment_role: :ANNUAL,
        threshold: 3.months,
        assessment_id: nil,
      )
      expect(grouped).to include(e2_a2, e3_a1)

      # within 3 months of 2 years ago
      grouped = Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: [e1, e2, e3],
        assessment_role: :ANNUAL,
        threshold: 3.months,
        assessment_id: e1_a1.id,
      )
      expect(grouped).to include(e1_a1)

      # within 3 months of 3 months ago (ensure closer assmt is chosen)
      grouped = Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: [e1, e2, e3],
        assessment_role: :ANNUAL,
        threshold: 3.months,
        assessment_id: e2_a2.id,
      )
      expect(grouped).to include(e2_a2, e3_a2)

      # within 6 months of 1 month ago (ensure closer assmt is chosen)
      grouped = Hmis::Hud::CustomAssessment.group_household_assessments(
        household_enrollments: [e1, e2, e3],
        assessment_role: :ANNUAL,
        threshold: 6.months,
        assessment_id: e3_a1.id,
      )
      expect(grouped).to include(e3_a1, e2_a2)
    end
  end
end
