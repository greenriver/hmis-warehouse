###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Enrollment, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  it 'detects date conflicts' do
    [
      # [ enter, exit, cmp enter, cmp exit, conflict expected ]
      ['2000-01-01', '2000-01-01', '2000-01-01', nil, true, 'enter on exited entry date'],
      ['2000-01-01', '2000-01-03', '2000-01-02', nil, true, 'enter between exited entry and exit'],
      ['2000-01-02', '2000-01-03', '2000-01-01', nil, true, 'enter before existing entry'],
      ['2000-01-01', nil,          '2000-01-02', nil, true, 'enter after another active'],
      ['2000-01-01', '2000-01-02', '2000-01-02', nil, false, 'enter on exited exit date'],
      ['2000-01-01', '2000-01-02', '2000-01-03', nil, false, 'enter after exited exit date'],

      ['2000-01-01', '2000-01-01', '2000-01-01', '2001-01-01', true, 'exit and enter on same day'],
      ['2001-01-02', nil,          '2001-01-01', '2001-01-03', true, 'exit after open entry'],
      ['2001-01-02', '2001-01-02', '2001-01-01', '2001-01-02', false, 'exit on same-day exited entry date'],
      ['2001-01-01', '2001-01-02', '2001-01-02', '2001-01-02', false, 'exit on exited entry date'],
      ['2001-01-02', nil,          '2001-01-01', '2001-01-02', false, 'exit on active entry date'],
      ['2001-01-03', '2001-01-04', '2001-01-01', '2001-01-02', false, 'exit before entry date'],
      ['2001-01-01', '2001-01-02', '2001-01-03', '2001-01-04', false, 'exit after exit date'],
    ].each do |row|
      message = row.pop
      expect_conflict = row.pop
      entry_date, exit_date, range_start, range_end = row.map { |s| s ? Date.parse(s) : nil }

      enrollment = create(:hmis_hud_enrollment, EntryDate: entry_date, data_source: ds1)
      if exit_date
        exit = create(
          :hmis_hud_exit,
          enrollment: enrollment,
          data_source: ds1,
          EnrollmentID: enrollment.enrollment_id,
          PersonalID: enrollment.personal_id,
        )
        # override calculated date from factory
        exit.update!(exit_date: exit_date)
      end

      conflict = enrollment.
        client.enrollments.
        with_conflicting_dates(project: enrollment.project, range: range_start..range_end).
        any?
      expect(conflict).to eq(expect_conflict), "#{message} should #{expect_conflict ? 'conflict' : 'not conflict'}"
    end
  end

  describe 'in progress enrollments' do
    let!(:enrollment) { build(:hmis_hud_enrollment) }
    before(:each) do
      enrollment.save_in_progress!
    end
  end

  describe 'saved enrollments' do
    let!(:enrollment) { create(:hmis_hud_enrollment) }

    before(:each) do
      create(:hmis_hud_exit, data_source: enrollment.data_source, enrollment: enrollment, client: enrollment.client)
      create(:hmis_hud_service, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_hud_event, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_income_benefit, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_disability, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_health_and_dv, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_current_living_situation, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_hud_assessment, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_employment_education, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_youth_education_status, data_source: enrollment.data_source, enrollment: enrollment)

      enrollment.save_not_in_progress!
    end

    it 'preserve shared data after destroy' do
      enrollment.destroy
      enrollment.reload

      [
        :project,
        :client,
        :user,
      ].each do |assoc|
        expect(enrollment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end
    end

    it 'destroy dependent data' do
      enrollment.reload
      [
        :exit,
        :services,
        :events,
        :income_benefits,
        :disabilities,
        :health_and_dvs,
        :current_living_situations,
        :assessments,
        :employment_educations,
        :youth_education_statuses,
      ].each do |assoc|
        expect(enrollment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end

      enrollment.destroy
      enrollment.reload

      [
        :exit,
        :services,
        :events,
        :income_benefits,
        :disabilities,
        :health_and_dvs,
        :current_living_situations,
        :assessments,
        :employment_educations,
        :youth_education_statuses,
      ].each do |assoc|
        expect(enrollment.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
      end
    end
  end

  describe 'enrollments status is set correctly:' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1 }
    let!(:e3) { create :hmis_hud_enrollment, data_source: ds1 }

    it 'household with two entered members' do
      e1.update(household_id: e2.household_id)
      expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ACTIVE')
      expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('ACTIVE')
    end

    describe 'entry statuses' do
      let!(:intake_assessment) { create :hmis_custom_assessment, data_source: ds1, data_collection_stage: 1 }

      before(:each) do
        # link e1 and e2
        e1.update(household_id: e2.household_id)

        # make e2 WIP
        e2.save_in_progress!
      end

      it 'household with one entered (e1) and one WIP with no intake assessment (e2)' do
        expect(e1).not_to be_in_progress
        expect(e2).to be_in_progress
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ANY_ENTRY_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_ENTRY_INCOMPLETE')
      end

      it 'household with one entered (e1) and one WIP with a WIP intake assessment (e2)' do
        intake_assessment.update(enrollment: e2, wip: true)

        expect(e1).not_to be_in_progress
        expect(e2).to be_in_progress
        expect(e2.intake_assessment).to be_present
        expect(e2.intake_assessment.in_progress?).to eq(true)
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ANY_ENTRY_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_ENTRY_INCOMPLETE')
      end

      it 'household with one entered (e1) and one WIP with a submitted intake assessment (e2, bad state)' do
        intake_assessment.update(enrollment: e2)

        expect(e1).not_to be_in_progress
        expect(e2).to be_in_progress
        expect(e2.intake_assessment).to be_present
        expect(e2.intake_assessment.in_progress?).to eq(false)
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ANY_ENTRY_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_ENTRY_INCOMPLETE')
      end
    end

    describe 'exit statuses' do
      let!(:exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e3, client: e3.client }
      let!(:exit_assessment) { create :hmis_custom_assessment, data_source: ds1, data_collection_stage: 3 }

      before(:each) do
        # make e3 exited
        exit.update(enrollment: e3)
        # link e2 and e3
        e2.update(household_id: e3.household_id)
      end

      it 'household with one exited (e3) and one unexited with no exit assessment (e2)' do
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('EXITED')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('ACTIVE')
      end

      it 'household with one exited (e3) and one unexited with a WIP exit assessment (e2)' do
        exit_assessment.update(enrollment: e2, wip: true)

        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('ANY_EXIT_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_EXIT_INCOMPLETE')
      end

      it 'household with one exited (e3) and one unexited with a submitted exit assessment (e2, bad state)' do
        exit_assessment.update(enrollment: e2)
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('ANY_EXIT_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_EXIT_INCOMPLETE')
      end

      describe 'two exited members' do
        let!(:exit2) { create :hmis_hud_exit, data_source: ds1, enrollment: e2, client: e2.client }
        it 'household with one exited (e3) and one exited with a submitted exit assessment (e2)' do
          exit_assessment.update(enrollment: e2)
          expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('EXITED')
          expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('EXITED')
        end
      end
    end
  end

  describe 'enrollment data collection features' do
    # see the system test drivers/hmis/spec/system/hmis/data_collection_features_spec.rb for more comprehensive tests

    context 'when there are rules of varying specificity applying to different clients' do
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 4 }
      let!(:definition) { create :hmis_form_definition, title: 'CLS', role: 'CURRENT_LIVING_SITUATION', identifier: 'custom_cls' }
      # Rule 1 is more specific for this project, but doesn't apply to non-HOH enrollment
      let!(:rule1) { create :hmis_form_instance, entity: p1, data_collected_about: 'HOH', role: 'CURRENT_LIVING_SITUATION', definition_identifier: 'custom_cls' }
      # Rule 2 is less specific for the project, but does applies to the non-HOH enrollment
      let!(:rule2) { create :hmis_form_instance, entity: nil, project_type: p1.project_type, role: 'CURRENT_LIVING_SITUATION', definition_identifier: 'custom_cls' }

      let!(:hoh_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.month.ago, household_id: 'household1', relationship_to_hoh: 1 }
      let!(:spouse_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 1.month.ago, household_id: 'household1', relationship_to_hoh: 3 }

      it 'should return the more specific rule for the HoH' do
        expect(hoh_enrollment.data_collection_features).to include(
          have_attributes(
            'role' => 'CURRENT_LIVING_SITUATION',
            'instance' => rule1,
            'data_collected_about' => 'HOH',
          ),
        )
      end

      it 'should return the less specific rule for the spouse' do
        expect(spouse_enrollment.data_collection_features).to include(
          have_attributes(
            'role' => 'CURRENT_LIVING_SITUATION',
            'instance' => rule2,
            'data_collected_about' => 'ALL_CLIENTS',
          ),
        )
      end
    end
  end

  describe 'occurrence point form instances' do
    let(:role) { :OCCURRENCE_POINT }
    let!(:definition) { create(:occurrence_point_form) }
    let!(:project) { create(:hmis_hud_project, data_source: ds1) }
    let!(:hoh_enrollment) { create(:hmis_hud_enrollment, project: project, data_source: ds1, household_id: 'household1', relationship_to_hoh: 1) }
    let!(:spouse_enrollment) { create(:hmis_hud_enrollment, project: project, data_source: ds1, household_id: 'household1', relationship_to_hoh: 3) }
    let(:legacy_expected_struct) do
      have_attributes(
        legacy: true,
        definition: have_attributes(identifier: 'move_in_date'), # default form seeded by JsonForms.seed_all
        data_collected_about: 'ALL_CLIENTS',
      )
    end

    before(:all) do
      # seed default FormDefinitions so that the default move_in_date form is present
      ::HmisUtil::JsonForms.seed_all
    end

    it 'does not return the form when no instance exists' do
      expect(hoh_enrollment.occurrence_point_forms).to be_empty
    end

    it 'does not return the form when an irrelevant instance exists' do
      create(:hmis_form_instance, role: role, entity: p1, active: true) # applies to a different project
      expect(hoh_enrollment.occurrence_point_forms).to be_empty
    end

    it 'does not return the form when an inactive instance exists' do
      create(:hmis_form_instance, role: role, entity: project, active: false, definition: definition)
      expect(hoh_enrollment.occurrence_point_forms).to be_empty
    end

    context 'when there is no instance, but Enrollment has a MoveInDate value' do
      let!(:spouse_enrollment) do
        create(
          :hmis_hud_enrollment,
          project: project,
          data_source: ds1,
          household_id: 'household1',
          relationship_to_hoh: 3,
          move_in_date: 3.weeks.ago,
        )
      end

      it 'does return the default move_in_date form' do
        expect(spouse_enrollment.occurrence_point_forms).to contain_exactly(legacy_expected_struct)
      end

      context 'when multiple irrelevant instances exist' do
        let!(:instance1) { create(:hmis_form_instance, role: role, project_type: 2, active: true, definition: definition) }
        let!(:instance2) { create(:hmis_form_instance, role: role, project_type: 3, active: true, definition: definition) }
        let!(:instance3) { create(:hmis_form_instance, role: role, project_type: 4, active: true, definition: definition) }
        let!(:inactive_instance) { create(:hmis_form_instance, role: role, project_type: 6, active: false, definition: definition) }

        it 'returns the default move_in_date form, with no duplicates' do
          expect(spouse_enrollment.occurrence_point_forms).to contain_exactly(legacy_expected_struct)
        end
      end

      context 'when a draft version of the form does not collect the same data' do
        let!(:draft_definition) { create(:occurrence_point_form, version: 2, status: :draft) }

        it 'returns the default move_in_date form' do
          expect(spouse_enrollment.occurrence_point_forms).to contain_exactly(legacy_expected_struct)
        end
      end
    end

    context 'when a relevant instance exists for all clients' do
      let!(:instance) { create(:hmis_form_instance, role: role, entity: project, active: true, definition: definition) }

      context 'when the only definition is in draft' do
        let!(:definition) { create(:occurrence_point_form, status: :draft) }
        it 'does not return the form' do
          expect(hoh_enrollment.occurrence_point_forms).to be_empty
          expect(spouse_enrollment.occurrence_point_forms).to be_empty
        end
      end

      context 'when the instance applies to all clients' do
        it 'returns the form for all clients' do
          expected = have_attributes(
            legacy: false,
            definition: definition,
            data_collected_about: 'ALL_CLIENTS',
          )
          expect(hoh_enrollment.occurrence_point_forms).to contain_exactly(expected)
          expect(spouse_enrollment.occurrence_point_forms).to contain_exactly(expected)
        end
      end
    end

    context 'when a relevant instance exists for HoH only' do
      let!(:instance) { create(:hmis_form_instance, role: role, entity: project, active: true, definition: definition, data_collected_about: :HOH) }

      it 'returns the form for HoH only' do
        expected = have_attributes(
          legacy: false,
          definition: definition,
          data_collected_about: 'HOH',
        )
        expect(hoh_enrollment.occurrence_point_forms).to contain_exactly(expected)
        expect(spouse_enrollment.occurrence_point_forms).to be_empty
      end

      context 'when legacy data exists for non-HoH client' do
        let!(:spouse_enrollment) do
          create(
            :hmis_hud_enrollment,
            project: project,
            data_source: ds1,
            household_id: 'household1',
            relationship_to_hoh: 3,
            move_in_date: 3.weeks.ago,
          )
        end

        it 'returns the default form for non-HoH' do
          expect(spouse_enrollment.occurrence_point_forms).to contain_exactly(legacy_expected_struct)
        end
      end

      context 'when legacy data exists for this occurrence point in another project' do
        let!(:spouses_other_enrollment) do
          create(
            :hmis_hud_enrollment,
            client: spouse_enrollment.client,
            project: p1, # some other project
            data_source: ds1,
            move_in_date: 3.weeks.ago,
          )
        end

        it 'does not return the form' do
          expect(spouse_enrollment.occurrence_point_forms).to be_empty
        end
      end
    end

    context 'PATH Status form' do
      let(:legacy_expected_struct) do
        have_attributes(
          legacy: true,
          definition: have_attributes(identifier: 'path_status'), # default form seeded by JsonForms.seed_all
          data_collected_about: 'ALL_CLIENTS',
        )
      end

      context 'when DateOfPATHStatus does not exist' do
        it 'does not return PATH status form' do
          expect(hoh_enrollment.occurrence_point_forms).to be_empty
        end
      end
      context 'when DateOfPATHStatus exists' do
        before(:each) { hoh_enrollment.update!(date_of_path_status: 3.weeks.ago) }
        it 'returns the default PATH status form' do
          expect(hoh_enrollment.occurrence_point_forms).to contain_exactly(legacy_expected_struct)
        end
      end
    end

    context 'Date of Engagement form' do
      let(:legacy_expected_struct) do
        have_attributes(
          legacy: true,
          definition: have_attributes(identifier: 'date_of_engagement'), # default form seeded by JsonForms.seed_all
          data_collected_about: 'ALL_CLIENTS',
        )
      end

      context 'when DateOfEngagement does not exist' do
        it 'does not return Date of engagement form' do
          expect(hoh_enrollment.occurrence_point_forms).to be_empty
        end
      end
      context 'when DateOfEngagement exists' do
        before(:each) { hoh_enrollment.update!(date_of_engagement: 3.weeks.ago) }
        it 'returns the default Date of engagement form' do
          expect(hoh_enrollment.occurrence_point_forms).to contain_exactly(legacy_expected_struct)
        end
      end
    end
  end
end
