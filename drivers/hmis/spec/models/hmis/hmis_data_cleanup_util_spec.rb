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
  let!(:e1) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds, project: p1 }
  let!(:e2) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds, project: p1 }
  let!(:e3) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds }
  let!(:e4) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds }

  before(:all) do
    # create cruft in other data sources
    [:destination_data_source, :source_data_source].each do |ds_factory|
      ds = create(ds_factory)
      proj = create(:hud_project, data_source_id: ds.id)
      client = create(:grda_warehouse_hud_client, data_source_id: ds.id)
      5.times do
        create(:grda_warehouse_hud_enrollment, data_source_id: ds.id, client: client, project: proj, DateCreated: 5.years.ago, DateUpdated: 5.years.ago)
      end
    end
  end

  def expect_leaves_non_hmis_data_alone(&block)
    expect do
      yield block
    end.to change(GrdaWarehouse::Hud::Enrollment, :count).by(0).
      and change(GrdaWarehouse::Version, :count).by(0).
      # none of the utils should set timestamps on any records
      and change(GrdaWarehouse::Hud::Enrollment.where(DateUpdated: 5.minutes.ago..), :count).by(0).
      and change(GrdaWarehouse::Hud::Service.where(DateUpdated: 5.minutes.ago..), :count).by(0).
      and change(GrdaWarehouse::Hud::CurrentLivingSituation.where(DateUpdated: 5.minutes.ago..), :count).by(0).
      and change(GrdaWarehouse::Hud::Client.where(DateUpdated: 5.minutes.ago..), :count).by(0)
  end

  context 'clear_enrollment_export_ids' do
    it 'works' do
      GrdaWarehouse::Hud::Enrollment.update_all(ExportID: 'XYZ')

      old_timestamp = e1.date_updated
      HmisDataCleanup::Util.clear_enrollment_export_ids!

      expect(e1.date_updated).to eq(old_timestamp)
      expect(GrdaWarehouse::Hud::Enrollment.where(data_source: hmis_ds).where.not(ExportID: nil).exists?).to be false
      expect(GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).where(ExportID: nil).exists?).to be false
    end

    it 'leaves no trace' do
      GrdaWarehouse::Hud::Enrollment.update_all(ExportID: 'XYZ')
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.clear_enrollment_export_ids!
      end
    end
  end

  context 'assign_missing_household_ids' do
    it 'works' do
      GrdaWarehouse::Hud::Enrollment.update_all(HouseholdID: nil)

      HmisDataCleanup::Util.assign_missing_household_ids!

      # all HMIS records have Household IDs
      expect(GrdaWarehouse::Hud::Enrollment.where(data_source: hmis_ds).where(HouseholdID: nil).exists?).to be false
      # non-HMIS records dont
      expect(GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).where(HouseholdID: nil).exists?).to be true
    end

    it 'leaves no trace' do
      GrdaWarehouse::Hud::Enrollment.update_all(HouseholdID: nil)
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.clear_enrollment_export_ids!
      end
    end
  end

  context 'make_sole_member_hoh' do
    it 'works' do
      e1.update(relationship_to_hoh: 99, household_id: 'multi-member-household')
      e2.update(relationship_to_hoh: 99, household_id: 'multi-member-household')
      e3.update(relationship_to_hoh: 99, household_id: 'individual-household') # should be updated
      # binding.pry

      # Hmis::Hud::Enrollment.hmis.group(:household_id).having(nf('COUNT', [:HouseholdID]).eq(1)).where.not(relationship_to_hoh: 1).select(:id)
      HmisDataCleanup::Util.make_sole_member_hoh!

      expect(e1.reload.relationship_to_hoh).to eq(99)
      expect(e2.reload.relationship_to_hoh).to eq(99)
      expect(e3.reload.relationship_to_hoh).to eq(1)
    end

    it 'doesnt touch non-HMIS enrollments' do
      GrdaWarehouse::Hud::Enrollment.update_all(relationship_to_hoh: 99)
      expect do
        HmisDataCleanup::Util.make_sole_member_hoh!
      end.to change(GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).heads_of_households, :count).by(0)
    end

    it 'leaves no trace' do
      GrdaWarehouse::Hud::Enrollment.update_all(relationship_to_hoh: 99)
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.make_sole_member_hoh!
      end
    end
  end

  context 'fix_incorrect_personal_id_references' do
    let!(:records_with_bad_references) do
      records = []
      shared_attributes = {
        data_source: hmis_ds,
        enrollment: e1,
        PersonalID: 'not-real',
        DateCreated: 5.years.ago,
        DateUpdated: 5.years.ago,
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
        DateCreated: 5.years.ago,
        DateUpdated: 5.years.ago,
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
      bad_service = create(:hmis_hud_service, :skip_validate, enrollment: e1, PersonalID: 'unmatched-id', DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds)
      good_service = create(:hmis_hud_service, :skip_validate, enrollment: e1, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds)

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

    it 'leaves no trace' do
      expect_leaves_non_hmis_data_alone { HmisDataCleanup::Util.fix_incorrect_personal_id_references! }
    end

    it 'dry run does nothing' do
      HmisDataCleanup::Util.fix_incorrect_personal_id_references!(dry_run: true)
      records_with_bad_references.each(&:reload)
      expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly('not-real')
    end
  end

  context 'all utilities' do
    it 'leave non-HMIS data untouched' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.update_all_enrollment_cocs!('KY-100')
      end
    end
  end
end
