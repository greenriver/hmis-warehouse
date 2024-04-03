###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe HmisDataCleanup::Util, type: :model do
  let!(:hmis_ds) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: hmis_ds }
  let!(:p1) { create :hmis_hud_project, data_source: hmis_ds, organization: o1 }
  let(:last_year) { 1.year.ago }
  let!(:e1) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p1 }
  let!(:e2) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p1 }
  let!(:e3) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds }
  let!(:e4) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds }

  before(:all) do
    # create cruft in other data sources
    [:destination_data_source, :source_data_source].each do |ds_factory|
      ds = create(ds_factory)
      proj = create(:hud_project, data_source_id: ds.id)
      client = create(:grda_warehouse_hud_client, data_source_id: ds.id)
      5.times do
        create(:grda_warehouse_hud_enrollment, data_source_id: ds.id, client: client, project: proj, DateCreated: 1.year.ago, DateUpdated: 1.year.ago)
      end
    end
  end

  let(:hmis_hud_classes) { Hmis::Hud::Project.hmis_classes.excluding(Hmis::Hud::Export) }

  def expect_leaves_non_hmis_data_alone(&block)
    expect do
      yield block
    end.to not_change(GrdaWarehouse::Version, :count).
      # Data in non-HMIS data sources should not be changed
      and(
        not_change do
          hmis_hud_classes.flat_map do |scope|
            scope.order(:id).where.not(data_source: hmis_ds).map(&:attributes)
          end
        end,
      ).
      # DateUpdated should not be changed on any records in any data source
      and(
        not_change do
          hmis_hud_classes.flat_map do |scope|
            scope.where(DateUpdated: 5.minutes.ago..).count
          end
        end,
      )
  end

  context 'enrollment with export ids' do
    before(:each)  { GrdaWarehouse::Hud::Enrollment.update_all(ExportID: 'XYZ') }

    it 'clears the exports' do
      HmisDataCleanup::Util.clear_enrollment_export_ids!

      expect(GrdaWarehouse::Hud::Enrollment.where(data_source: hmis_ds).where.not(ExportID: nil).exists?).to be false
      expect(GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).where(ExportID: nil).exists?).to be false
    end

    it 'does not make unexpected changes' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.clear_enrollment_export_ids!
      end
    end
  end

  context 'enrollments without HouseholdIDs' do
    before(:each) { GrdaWarehouse::Hud::Enrollment.update_all(HouseholdID: nil) }
    it 'assigns HouseholdIDs to HMIS records' do
      HmisDataCleanup::Util.assign_missing_household_ids!

      # all HMIS records have Household IDs
      expect(GrdaWarehouse::Hud::Enrollment.where(data_source: hmis_ds).where(HouseholdID: nil).exists?).to be false
      # non-HMIS records dont
      expect(GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).where(HouseholdID: nil).exists?).to be true
    end

    it 'does not make unexpected changes' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.clear_enrollment_export_ids!
      end
    end
  end

  context 'single-person households with no HoH' do
    before(:each) do
      e1.update(relationship_to_hoh: 99, household_id: 'multi-member-household')
      e2.update(relationship_to_hoh: 99, household_id: 'multi-member-household')
      e3.update(relationship_to_hoh: 99, household_id: 'individual-household') # should be updated

      # cruft in other data sources that shouldn't be touched
      GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).update_all(relationship_to_hoh: 99)
    end

    it 'assigns HoH' do
      HmisDataCleanup::Util.make_sole_member_hoh!

      expect(e1.reload.relationship_to_hoh).to eq(99)
      expect(e2.reload.relationship_to_hoh).to eq(99)
      expect(e3.reload.relationship_to_hoh).to eq(1)
    end

    it 'does not make unexpected changes' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.make_sole_member_hoh!
      end
    end
  end

  context 'records with incorrect PersonalID references' do
    let!(:records_with_bad_references) do
      records = []
      shared_attributes = {
        data_source: hmis_ds,
        enrollment: e1,
        PersonalID: 'not-real',
        DateCreated: last_year,
        DateUpdated: last_year,
      }
      records << create(:hmis_hud_service, :skip_validate, **shared_attributes)
      records << create(:hmis_income_benefit, :skip_validate, **shared_attributes)
      records << create(:hmis_health_and_dv, :skip_validate, **shared_attributes)
      records << create(:hmis_youth_education_status, :skip_validate, **shared_attributes)
      records << create(:hmis_employment_education, :skip_validate, **shared_attributes)
      records << create(:hmis_disability, :skip_validate, **shared_attributes)
      records << create(:hmis_hud_exit, :skip_validate, **shared_attributes)
      records << create(:hmis_current_living_situation, :skip_validate, **shared_attributes)
      records << create(:hmis_hud_assessment, :skip_validate, **shared_attributes)
      records << create(:hmis_assessment_question, :skip_validate, **shared_attributes)
      records << create(:hmis_assessment_result, :skip_validate, **shared_attributes)
      records << create(:hmis_hud_event, :skip_validate, **shared_attributes)
      records
    end

    let!(:records_with_good_references) do
      records = []
      shared_attributes = {
        data_source: hmis_ds,
        enrollment: e1,
        client: e1.client,
        DateCreated: last_year,
        DateUpdated: last_year,
      }
      records << create(:hmis_hud_service, **shared_attributes)
      records << create(:hmis_income_benefit, **shared_attributes)
      records << create(:hmis_health_and_dv, **shared_attributes)
      records << create(:hmis_youth_education_status, **shared_attributes)
      records << create(:hmis_employment_education, **shared_attributes)
      records << create(:hmis_disability, **shared_attributes)
      records << create(:hmis_hud_exit, **shared_attributes)
      records << create(:hmis_current_living_situation, **shared_attributes)
      records << create(:hmis_hud_assessment, **shared_attributes)
      records << create(:hmis_assessment_question, **shared_attributes)
      records << create(:hmis_assessment_result, **shared_attributes)
      records << create(:hmis_hud_event, **shared_attributes)
      records
    end

    it 'works for services' do
      bad_service = create(:hmis_hud_service, :skip_validate, enrollment: e1, PersonalID: 'unmatched-id', data_source: hmis_ds)
      good_service = create(:hmis_hud_service, :skip_validate, enrollment: e1, data_source: hmis_ds)

      HmisDataCleanup::Util.fix_incorrect_personal_id_references!(classes: [Hmis::Hud::Service])
      [bad_service, good_service].each(&:reload)
      expect(bad_service.personal_id).to eq(e1.personal_id)
      expect(bad_service.enrollment).to be_present
      expect(good_service.enrollment).to be_present
    end

    it 'works for all record types' do
      expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly('not-real')

      HmisDataCleanup::Util.fix_incorrect_personal_id_references!

      records_with_bad_references.each(&:reload)
      expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly(e1.personal_id)
    end

    it 'does not make unexpected changes' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.fix_incorrect_personal_id_references!
      end
    end

    it 'dry run does nothing' do
      HmisDataCleanup::Util.fix_incorrect_personal_id_references!(dry_run: true)

      records_with_bad_references.each(&:reload)
      expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly('not-real')
    end
  end

  context 'with duplicate custom assessments' do
    let(:form_definition) { create(:hmis_form_definition) }
    let(:cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment') }
    let!(:today) { Date.current }

    let!(:not_dupe) do
      create(:hmis_custom_assessment, client: e1.client, enrollment: e1, AssessmentDate: today, definition: form_definition).tap do |ca|
        create(:hmis_custom_data_element, data_element_definition: cded, owner: ca, value_string: 'test1')
      end
    end
    let!(:dupes) do
      2.times.map do
        create(:hmis_custom_assessment, client: e1.client, enrollment: e1, AssessmentDate: today, definition: form_definition) do |ca|
          create(:hmis_custom_data_element, data_element_definition: cded, owner: ca, value_string: 'test2')
        end
      end
    end

    it 'identifies duplicates' do
      results = HmisDataCleanup::DuplicateRecordsReport.new.duplicate_custom_assessments(hmis_ds)
      expect(results).to contain_exactly(dupes.map(&:id))
    end
  end

  context 'with duplicate custom services' do
    let(:custom_service_type) { create(:hmis_custom_service_type) }
    let(:cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomService') }
    let!(:today) { Date.current }

    let!(:not_dupe) do
      create(:hmis_custom_service, client: e1.client, enrollment: e1, DateProvided: today, custom_service_type: custom_service_type).tap do |cs|
        create(:hmis_custom_data_element, data_element_definition: cded, owner: cs, value_string: 'test1')
      end
    end
    let!(:dupes) do
      2.times.map do
        create(:hmis_custom_service, client: e1.client, enrollment: e1, DateProvided: today, custom_service_type: custom_service_type) do |cs|
          create(:hmis_custom_data_element, data_element_definition: cded, owner: cs, value_string: 'test2')
        end
      end
    end

    it 'identifies duplicates' do
      results = HmisDataCleanup::DuplicateRecordsReport.new.duplicate_custom_services(hmis_ds)
      expect(results).to contain_exactly(dupes.map(&:id))
    end
  end

  context 'enrollments with incorrect EnrollmentCoCs' do
    before(:each) do
      e1.update(enrollment_coc: 'MA-500')
      e2.update(enrollment_coc: 'KY-600')
    end
    it 'updates cocs' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.update_all_enrollment_cocs!('KY-600')
      end

      expect(e1.reload.enrollment_coc).to eq('KY-600')
    end
  end
end
