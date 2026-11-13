###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/hmis_data_cleanup_spec_helpers'

RSpec.describe HmisDataCleanup::Util, type: :model do
  include_context 'hmis data cleanup spec helpers'

  let!(:hmis_ds) { create :hmis_data_source }
  let(:today) { Date.current }
  let(:yesterday) { today - 1.day }
  let(:default_enrollment_attrs) do
    {
      data_source: hmis_ds,
      date_updated: yesterday,
      date_created: yesterday,
    }
  end
  let!(:o1) { create :hmis_hud_organization, data_source: hmis_ds }
  let!(:p1) { create :hmis_hud_project, data_source: hmis_ds, organization: o1 }
  let(:last_year) { 1.year.ago }
  let!(:e1) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p1 }
  let!(:e2) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p1 }
  let!(:e3) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds }
  let!(:e4) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds }

  describe '#clear_enrollment_export_ids!' do
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

  describe '#assign_missing_household_ids!' do
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

  describe '#fix_disabling_condition_nils!' do
    before(:each) do
      # use update_columns to bypass before_save hook
      e1.update_columns(disabling_condition: nil)
      e2.update_columns(disabling_condition: nil)
      e3.update_columns(disabling_condition: 1)
      e4.update_columns(disabling_condition: 99)
      GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).update_all(disabling_condition: nil)
    end

    it 'sets DisablingCondition from nil to 99, leaving other DisablingConditions unchanged' do
      expect do
        HmisDataCleanup::Util.fix_disabling_condition_nils!
        [e1, e2, e3, e4].map(&:reload)
      end.to change(e1, :disabling_condition).from(nil).to(99).
        and change(e2, :disabling_condition).from(nil).to(99).
        and not_change(e3, :disabling_condition).
        and not_change(e4, :disabling_condition)
    end

    it 'does not make changes to non-hmis data' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.fix_disabling_condition_nils!
      end
    end
  end

  describe '#fix_race_gender_99s!' do
    let!(:race_fields) { HudHelper.util.races.keys.excluding('RaceNone') }
    let!(:gender_fields) { HudHelper.util.gender_fields.excluding(:GenderNone) }

    context 'when the client has some race/gender fields specified' do
      let!(:c1_with_race_and_gender) do
        create(
          :hmis_hud_client,
          data_source: hmis_ds,
          RaceNone: nil,
          GenderNone: nil,
          **race_fields.map { |field| [field, 99] }.to_h,
          **gender_fields.map { |field| [field, 99] }.to_h,
          AmIndAKNative: 1,
          Woman: 1,
        )
      end

      it 'updates race/gender values of 99 to 0' do
        expect do
          HmisDataCleanup::Util.fix_race_gender_99s!
          c1_with_race_and_gender.reload
        end.to change { c1_with_race_and_gender.Asian }.from(99).to(0).
          and change { c1_with_race_and_gender.BlackAfAmerican }.from(99).to(0).
          and change { c1_with_race_and_gender.NativeHIPacific }.from(99).to(0).
          and change { c1_with_race_and_gender.White }.from(99).to(0).
          and change { c1_with_race_and_gender.HispanicLatinaeo }.from(99).to(0).
          and change { c1_with_race_and_gender.MidEastNAfrican }.from(99).to(0).
          and(not_change { c1_with_race_and_gender.AmIndAKNative }).
          and(not_change { c1_with_race_and_gender.RaceNone }).
          and change { c1_with_race_and_gender.Man }.from(99).to(0).
          and change { c1_with_race_and_gender.CulturallySpecific }.from(99).to(0).
          and change { c1_with_race_and_gender.DifferentIdentity }.from(99).to(0).
          and change { c1_with_race_and_gender.NonBinary }.from(99).to(0).
          and change { c1_with_race_and_gender.Transgender }.from(99).to(0).
          and change { c1_with_race_and_gender.Questioning }.from(99).to(0).
          and(not_change { c1_with_race_and_gender.Woman }).
          and(not_change { c1_with_race_and_gender.GenderNone })
      end
    end

    context 'when the client has no race/gender fields specified and none field is set' do
      let!(:c2_doesnt_know) do
        create(
          :hmis_hud_client,
          data_source: hmis_ds,
          RaceNone: 8,
          GenderNone: 8,
          **race_fields.map { |field| [field, 99] }.to_h,
          **gender_fields.map { |field| [field, 99] }.to_h,
        )
      end

      let!(:c3_prefers_not_to) do
        create(
          :hmis_hud_client,
          data_source: hmis_ds,
          RaceNone: 9,
          GenderNone: 9,
          **race_fields.map { |field| [field, 99] }.to_h,
          **gender_fields.map { |field| [field, 99] }.to_h,
        )
      end

      let!(:c4_data_not_collected) do
        create(
          :hmis_hud_client,
          data_source: hmis_ds,
          RaceNone: 99,
          GenderNone: 99,
          **race_fields.map { |field| [field, 99] }.to_h,
          **gender_fields.map { |field| [field, 99] }.to_h,
        )
      end

      it 'updates race/gender values of 99 to 0' do
        clients = [c2_doesnt_know, c3_prefers_not_to, c4_data_not_collected]
        expect do
          HmisDataCleanup::Util.fix_race_gender_99s!
          clients.each(&:reload)
        end.to change { clients.map(&:AmIndAKNative).uniq.sole }.from(99).to(0).
          and change { clients.map(&:Asian).uniq.sole }.from(99).to(0).
          and change { clients.map(&:BlackAfAmerican).uniq.sole }.from(99).to(0).
          and change { clients.map(&:NativeHIPacific).uniq.sole }.from(99).to(0).
          and change { clients.map(&:White).uniq.sole }.from(99).to(0).
          and change { clients.map(&:HispanicLatinaeo).uniq.sole }.from(99).to(0).
          and change { clients.map(&:MidEastNAfrican).uniq.sole }.from(99).to(0).
          and(not_change { clients.map(&:RaceNone) }).
          and change { clients.map(&:Woman).uniq.sole }.from(99).to(0).
          and change { clients.map(&:Man).uniq.sole }.from(99).to(0).
          and change { clients.map(&:CulturallySpecific).uniq.sole }.from(99).to(0).
          and change { clients.map(&:DifferentIdentity).uniq.sole }.from(99).to(0).
          and change { clients.map(&:NonBinary).uniq.sole }.from(99).to(0).
          and change { clients.map(&:Transgender).uniq.sole }.from(99).to(0).
          and change { clients.map(&:Questioning).uniq.sole }.from(99).to(0).
          and(not_change { clients.map(&:GenderNone) })
      end
    end

    context 'when the client has nil RaceNone and/or GenderNone' do
      let!(:c5_none_field_nil) do
        create(
          :hmis_hud_client,
          data_source: hmis_ds,
          RaceNone: nil,
          GenderNone: nil,
          **race_fields.map { |field| [field, 0] }.to_h,
          **gender_fields.map { |field| [field, 0] }.to_h,
        )
      end

      let!(:c6_with_race_and_gender) do
        create(
          :hmis_hud_client,
          data_source: hmis_ds,
          RaceNone: nil,
          GenderNone: nil,
          AmIndAKNative: 1,
          Woman: 1,
        )
      end

      it 'updates RaceNone and GenderNone to 99 when all race/gender values are 0' do
        expect do
          HmisDataCleanup::Util.fix_race_gender_99s!
          c5_none_field_nil.reload
          c6_with_race_and_gender.reload
        end.to change(c5_none_field_nil, :RaceNone).from(nil).to(99).
          and change(c5_none_field_nil, :GenderNone).from(nil).to(99).
          and not_change(c5_none_field_nil, :race_fields).
          and not_change(c5_none_field_nil, :gender_fields).
          and not_change(c6_with_race_and_gender, :RaceNone).
          and not_change(c6_with_race_and_gender, :GenderNone)
      end
    end

    context 'when there is bad data on non-hmis data source' do
      let!(:other_ds_client) do
        create(
          :hmis_hud_client,
          data_source: other_source_ds,
          RaceNone: 99,
          GenderNone: 99,
          **race_fields.map { |field| [field, 99] }.to_h,
          **gender_fields.map { |field| [field, 99] }.to_h,
        )
      end

      it 'does not update clients in other data sources' do
        expect_leaves_non_hmis_data_alone do
          HmisDataCleanup::Util.fix_race_gender_99s!
        end
      end
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
      e1.update!(enrollment_coc: 'MA-500')
      e2.update!(enrollment_coc: 'KY-600')
    end
    it 'updates cocs' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.update_all_enrollment_cocs!('KY-600')
      end

      expect(e1.reload.enrollment_coc).to eq('KY-600')
    end
  end

  context 'with duplicate bed nights' do
    before(:each) do
      # canary records
      create(:hmis_hud_service_bednight, date_provided: yesterday, client: e2.client, enrollment: e2, **default_enrollment_attrs)
      create(:hmis_hud_service_bednight, date_provided: yesterday, client: e1.client, enrollment: e1, **default_enrollment_attrs)
      create(:hmis_hud_service_bednight, date_provided: today, client: e1.client, enrollment: e1, **default_enrollment_attrs)
    end
    let!(:duplicate) do
      create(:hmis_hud_service_bednight, date_provided: today, client: e1.client, enrollment: e1, **default_enrollment_attrs)
    end

    it 'deletes duplicates' do
      expect { HmisDataCleanup::Util.delete_duplicate_bed_nights! }.to(
        [
          change { Hmis::Hud::Service.where(id: duplicate.id).count }.to(0),
          change { Hmis::Hud::Service.count }.by(-1),
        ].reduce(&:and),
      )
    end

    it 'has no side-effects' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.delete_duplicate_bed_nights!
      end
    end
  end

  context 'with duplicate exits' do
    before(:each) do
      # canary records
      create(:hmis_base_hud_exit, exit_date: yesterday, client: e2.client, enrollment: e2, **default_enrollment_attrs)
      create(:hmis_base_hud_exit, exit_date: yesterday, client: e1.client, enrollment: e1, **default_enrollment_attrs)
    end
    let!(:duplicate) do
      create(:hmis_base_hud_exit, exit_date: today, client: e1.client, enrollment: e1, **default_enrollment_attrs)
    end

    it 'deletes duplicates' do
      expect { HmisDataCleanup::Util.delete_duplicate_exit_records! }.to(
        [
          change { Hmis::Hud::Exit.where(id: duplicate.id).count }.to(0),
          change { Hmis::Hud::Exit.count }.by(-1),
        ].reduce(&:and),
      )
    end

    it 'has no side-effects' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.delete_duplicate_exit_records!
      end
    end
  end

  context 'with household ids duplicated across projects' do
    before(:each) do
      p2 = create(:hmis_hud_project, data_source: hmis_ds, organization: o1)
      e1.update!(household_id: 'ABCDEF', project: p1)
      e2.update!(household_id: 'ABCDEF', project: p2)
      e3.update!(household_id: 'ABCDEF', project: p2)
    end

    it 'reassigns household IDs correctly' do
      expect { HmisDataCleanup::Util.reassign_duplicate_household_ids! }.to(
        [
          change { Hmis::Hud::Enrollment.find(e1.id).household_id },
          change { Hmis::Hud::Enrollment.find(e2.id).household_id },
          change { Hmis::Hud::Enrollment.find(e3.id).household_id },
        ].reduce(&:and),
      )

      [e1, e2, e3].map(&:reload)
      expect(e1.household_id).not_to eq(e2.household_id)
      expect(e2.household_id).to eq(e3.household_id), 'household remains intact'
    end

    it 'has no side-effects' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.reassign_duplicate_household_ids!
      end
    end
  end

  context 'with duplicate deleted EnrollmentIDs' do
    let(:dup_key) { 'ABCDEF' }
    before(:each) do
      e1.update!(EnrollmentID: dup_key, DateDeleted: 1.week.ago, project: p1)
      e2.update!(EnrollmentID: dup_key, DateDeleted: nil, project: p1)
      e3.update!(EnrollmentID: dup_key, DateDeleted: 1.week.ago, project: p1)

      # duplicate in a different project
      p2 = create(:hmis_hud_project, data_source: hmis_ds, organization: o1)
      e4.update!(EnrollmentID: dup_key, DateDeleted: 1.week.ago, project: p2)

      # duplicate in a different data source
      other_enrollments.first.update!(EnrollmentID: dup_key)
    end

    it 'hard-deletes duplicate enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.with_deleted.where(EnrollmentID: dup_key).count).to eq(5)

      expect { HmisDataCleanup::Util.hard_delete_duplicate_deleted_enrollments! }.to(
        [
          change { GrdaWarehouse::Hud::Enrollment.only_deleted.count }.by(-2),
          not_change { GrdaWarehouse::Hud::Enrollment.count },
          change { Hmis::Hud::Enrollment.hmis.only_deleted.where(EnrollmentID: dup_key).count }.to(1), # the one in another project
        ].reduce(&:and),
      )

      expect(GrdaWarehouse::Hud::Enrollment.with_deleted.where(id: [e1.id, e3.id])).to be_empty
      expect(e2.reload).to be_present
    end

    it 'keeps 1 deleted enrollment if ALL the dups are deleted' do
      e2.update!(DateDeleted: 2.days.ago)

      expect { HmisDataCleanup::Util.hard_delete_duplicate_deleted_enrollments! }.to(
        [
          change { GrdaWarehouse::Hud::Enrollment.only_deleted.count }.by(-2),
          not_change { GrdaWarehouse::Hud::Enrollment.count },
        ].reduce(&:and),
      )

      expect(GrdaWarehouse::Hud::Enrollment.with_deleted.where(id: [e1.id, e3.id])).to be_empty
      expect(e2.reload).to be_present
    end

    it 'has no side-effects' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.hard_delete_duplicate_deleted_enrollments!
      end
    end
  end

  context 'with Move-in Dates on non-HoH members' do
    let(:hoh) { create(:hmis_hud_enrollment, move_in_date: 1.month.ago, data_source: hmis_ds, project: p1) }
    let(:hhm) { create(:hmis_hud_enrollment, move_in_date: 1.month.ago, data_source: hmis_ds, project: p1, relationship_to_hoh: 99, household_id: hoh.household_id) }

    it 'clears move-in date from non-HoH member' do
      expect do
        HmisDataCleanup::Util.clear_household_move_in_dates!(hmis_ds.id)
        [hhm, hoh].map(&:reload)
      end.to change(hhm, :move_in_date).to(nil).
        and(not_change(hoh, :move_in_date)).
        and(not_change { hhm.date_updated.to_fs(:db) })
    end

    it 'does not clear move-in date if household has no HoH' do
      hoh.update!(relationship_to_hoh: 99)

      expect do
        HmisDataCleanup::Util.clear_household_move_in_dates!(hmis_ds.id)
        [hhm, hoh].map(&:reload)
      end.to not_change(hhm, :move_in_date).
        and(not_change(hoh, :move_in_date)).
        and(not_change { hhm.date_updated.to_fs(:db) })
    end
  end
end
