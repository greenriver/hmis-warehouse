###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/hmis_data_cleanup_spec_helpers'

# Unit/behavioral spec for HmisDataCleanup::FixIncorrectPersonalIdReferences.
#
# FixIncorrectPersonalIdReferences is not import-specific; it is shared by the post-ingest import extension,
# UndoMergeClientsJob, and can also be called directly from a Rails console.
# This spec exercises the shared implementation directly:
# all enrollment-related record types, dry_run, enrollment_ids/project_ids scoping, orphan handling,
# and safety checks (non-HMIS data left alone, no spurious DateUpdated changes).
#
# For import pipeline wiring, see the fixture spec at
# drivers/hmis_csv_importer/spec/models/importer/twenty_twenty_six/fix_incorrect_personal_id_references_spec.rb.
RSpec.describe HmisDataCleanup::FixIncorrectPersonalIdReferences, type: :model do
  include_context 'hmis data cleanup spec helpers'

  let!(:hmis_ds) { create :hmis_data_source }
  let(:today) { Date.current }
  let(:last_year) { 1.year.ago }
  let!(:o1) { create :hmis_hud_organization, data_source: hmis_ds }
  let!(:p1) { create :hmis_hud_project, data_source: hmis_ds, organization: o1 }
  let!(:e1) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p1 }
  let!(:e2) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p1 }

  def run!(**args)
    described_class.run!(data_source_id: hmis_ds.id, **args)
  end

  let(:related_record_factories) do
    [
      :hmis_hud_service,
      :hmis_income_benefit,
      :hmis_health_and_dv,
      :hmis_youth_education_status,
      :hmis_employment_education,
      :hmis_disability,
      :hmis_hud_exit,
      :hmis_current_living_situation,
      :hmis_hud_assessment,
      :hmis_assessment_question,
      :hmis_assessment_result,
      :hmis_hud_event,
      :hmis_custom_service, # custom HUD-style table, uses PersonalID+EnrollmentID association
      :hmis_custom_assessment, # custom HUD-style table, uses PersonalID+EnrollmentID association
      :hmis_hud_custom_case_note, # custom HUD-style table, uses PersonalID+EnrollmentID association
    ]
  end
  let!(:records_with_bad_references) do
    records = []
    shared_attributes = {
      data_source: hmis_ds,
      enrollment: e1,
      PersonalID: 'not-real',
      DateCreated: last_year,
      DateUpdated: last_year,
    }
    related_record_factories.each do |factory|
      records << create(factory, :skip_validate, **shared_attributes)
    end
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
    related_record_factories.each do |factory|
      records << create(factory, **shared_attributes)
    end
  end

  it 'works for services' do
    bad_service = create(:hmis_hud_service, :skip_validate, enrollment: e1, PersonalID: 'unmatched-id', data_source: hmis_ds)
    good_service = create(:hmis_hud_service, :skip_validate, enrollment: e1, data_source: hmis_ds)

    run!(classes: [Hmis::Hud::Service])
    [bad_service, good_service].each(&:reload)
    expect(bad_service.personal_id).to eq(e1.personal_id)
    expect(bad_service.enrollment).to be_present
    expect(good_service.enrollment).to be_present
  end

  it 'works for all record types' do
    expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly('not-real')

    run!

    records_with_bad_references.each(&:reload)
    expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly(e1.personal_id)
  end

  it 'does not make unexpected changes' do
    expect_leaves_non_hmis_data_alone do
      run!
    end
  end

  it 'dry run does nothing' do
    run!(dry_run: true)

    records_with_bad_references.each(&:reload)
    expect(records_with_bad_references.map(&:PersonalID).uniq).to contain_exactly('not-real')
  end

  context 'with enrollment_ids' do
    let!(:bad_service_e1) { create(:hmis_hud_service, :skip_validate, enrollment: e1, PersonalID: 'wrong-id-1', data_source: hmis_ds) }
    let!(:bad_service_e2) { create(:hmis_hud_service, :skip_validate, enrollment: e2, PersonalID: 'wrong-id-2', data_source: hmis_ds) }
    let!(:bad_income_e1) { create(:hmis_income_benefit, :skip_validate, enrollment: e1, PersonalID: 'wrong-id-1', data_source: hmis_ds) }
    let!(:bad_income_e2) { create(:hmis_income_benefit, :skip_validate, enrollment: e2, PersonalID: 'wrong-id-2', data_source: hmis_ds) }

    it 'only fixes records for the given enrollments' do
      run!(enrollment_ids: [e1.enrollment_id])

      [bad_service_e1, bad_service_e2, bad_income_e1, bad_income_e2].each(&:reload)
      # Records for e1 should be fixed
      expect(bad_service_e1.personal_id).to eq(e1.personal_id)
      expect(bad_income_e1.personal_id).to eq(e1.personal_id)
      # Records for e2 should NOT be fixed
      expect(bad_service_e2.personal_id).to eq('wrong-id-2')
      expect(bad_income_e2.personal_id).to eq('wrong-id-2')
    end
  end

  context 'with project_ids' do
    let!(:p2) { create :hmis_hud_project, data_source: hmis_ds, organization: o1 }
    let!(:e_p2) { create :hmis_hud_enrollment, DateCreated: last_year, DateUpdated: last_year, data_source: hmis_ds, project: p2 }
    let!(:bad_service_p1) { create(:hmis_hud_service, :skip_validate, enrollment: e1, PersonalID: 'wrong-id-1', data_source: hmis_ds) }
    let!(:bad_service_p2) { create(:hmis_hud_service, :skip_validate, enrollment: e_p2, PersonalID: 'wrong-id-2', data_source: hmis_ds) }

    it 'only fixes records for enrollments in the given projects' do
      run!(project_ids: [p1.project_id])

      [bad_service_p1, bad_service_p2].each(&:reload)
      expect(bad_service_p1.personal_id).to eq(e1.personal_id)
      expect(bad_service_p2.personal_id).to eq('wrong-id-2')
    end
  end

  it 'raises when both enrollment_ids and project_ids are provided' do
    expect do
      run!(enrollment_ids: [e1.id], project_ids: [p1.project_id])
    end.to raise_error(ArgumentError, 'Pass enrollment_ids or project_ids, but not both')
  end

  context 'with an orphaned record (EnrollmentID not found)' do
    let!(:orphan_service) { create(:hmis_hud_service, :skip_validate, enrollment: e1, EnrollmentID: 'does-not-exist', PersonalID: 'also-wrong', data_source: hmis_ds) }

    it 'leaves the orphan unchanged' do
      run!

      orphan_service.reload
      expect(orphan_service.personal_id).to eq('also-wrong')
    end
  end
end
