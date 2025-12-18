###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::TransferEnrollmentProjectJob, type: :model do
  let!(:data_source) { create(:hmis_data_source) }

  let!(:organization) { create(:hmis_hud_organization, data_source: data_source) }

  let!(:source_project) { create(:hmis_hud_project, data_source: data_source, organization: organization) }
  let!(:target_project) { create(:hmis_hud_project, data_source: data_source, organization: organization) }

  let!(:client1) { create(:hmis_hud_client, data_source: data_source) }
  let!(:client2) { create(:hmis_hud_client, data_source: data_source) }

  let!(:enrollment1) { create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client1) }
  let!(:enrollment2) { create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client2) }

  # cruft: other enrollments in the source and target projects
  let!(:cruft_e1) { create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client1) }
  let!(:cruft_e2) { create(:hmis_hud_enrollment, data_source: data_source, project: source_project) }
  let!(:cruft_e3) { create(:hmis_hud_enrollment, data_source: data_source, project: target_project) }
  let(:cruft_enrollments) { [cruft_e1, cruft_e2, cruft_e3] }

  describe 'successful transfer' do
    it 'transfers enrollments to target project' do
      expect do
        described_class.perform_now(
          enrollment_ids: [enrollment1.id, enrollment2.id],
          source_project_id: source_project.id,
          target_project_id: target_project.id,
        )
        [enrollment1, enrollment2, *cruft_enrollments].each(&:reload)
      end.to not_change(Hmis::Hud::Enrollment, :count).
        and change(enrollment1, :project_pk).from(source_project.id).to(target_project.id).
        and change(enrollment2, :project_pk).from(source_project.id).to(target_project.id).
        and change(enrollment1, :project_id).from(source_project.project_id).to(target_project.project_id).
        and change(enrollment2, :project_id).from(source_project.project_id).to(target_project.project_id).
        and not_change(cruft_e1, :project_pk).
        and not_change(cruft_e2, :project_pk).
        and not_change(cruft_e3, :project_pk)
    end

    it 'handles dry run without making changes' do
      expect do
        described_class.perform_now(
          enrollment_ids: [enrollment1.id],
          source_project_id: source_project.id,
          target_project_id: target_project.id,
          dry_run: true,
        )
      end.to not_change(enrollment1.reload, :project_pk)
    end

    context 'with WIP enrollments' do
      before(:each) do
        enrollment1.save_in_progress!
      end

      it 'transfers WIP enrollments to target project, maintaining WIP status' do
        expect do
          described_class.perform_now(
            enrollment_ids: [enrollment1.id],
            source_project_id: source_project.id,
            target_project_id: target_project.id,
          )
          enrollment1.reload
        end.to not_change(Hmis::Hud::Enrollment, :count).
          and change(enrollment1, :project_pk).from(source_project.id).to(target_project.id).
          and not_change(enrollment1, :project_id).from(nil) # WIP enrollments have a nil project_id

        expect(enrollment1.in_progress?).to eq(true)
      end
    end

    context 'with exited enrollments' do
      let!(:e1_exit) { create(:hmis_hud_exit, enrollment: enrollment1) }

      it 'transfers exited enrollments to target project, maintaining exited status' do
        expect do
          described_class.perform_now(
            enrollment_ids: [enrollment1.id],
            source_project_id: source_project.id,
            target_project_id: target_project.id,
          )
          enrollment1.reload
        end.to not_change(Hmis::Hud::Enrollment, :count).
          and change(enrollment1, :project_pk).from(source_project.id).to(target_project.id).
          and change(enrollment1, :project_id).from(source_project.project_id).to(target_project.project_id)

        expect(enrollment1.exit_date).to be_present
      end
    end

    context 'with unit assignments' do
      let!(:unit) { create(:hmis_unit, project: source_project) }
      let!(:unit_occupancy) { create(:hmis_unit_occupancy, unit: unit, enrollment: enrollment1) }

      it 'releases unit assignments' do
        expect do
          described_class.perform_now(
            enrollment_ids: [enrollment1.id],
            source_project_id: source_project.id,
            target_project_id: target_project.id,
          )
        end.to change { enrollment1.reload.active_unit_occupancy }.from(unit_occupancy).to(nil)
      end
    end
  end

  describe 'validation errors' do
    it 'raises error when source project not found' do
      expect do
        described_class.perform_now(
          enrollment_ids: [enrollment1.id],
          source_project_id: 999999,
          target_project_id: target_project.id,
        )
      end.to raise_error('Source project not found: 999999')
    end

    it 'raises error when target project not found' do
      expect do
        described_class.perform_now(
          enrollment_ids: [enrollment1.id],
          source_project_id: source_project.id,
          target_project_id: 999999,
        )
      end.to raise_error('Target project not found: 999999')
    end

    it 'raises error when projects are in different data sources' do
      other_data_source = create(:hmis_data_source)
      other_project = create(:hmis_hud_project, data_source: other_data_source)

      expect do
        described_class.perform_now(
          enrollment_ids: [enrollment1.id],
          source_project_id: source_project.id,
          target_project_id: other_project.id,
        )
      end.to raise_error('Source and target project must be in the same data source')
    end

    it 'raises error when enrollments not found in source project' do
      other_enrollment = create(:hmis_hud_enrollment, data_source: data_source)

      expect do
        described_class.perform_now(
          enrollment_ids: [enrollment1.id, other_enrollment.id],
          source_project_id: source_project.id,
          target_project_id: target_project.id,
        )
      end.to raise_error(/Some enrollments not found in source project/)
    end
  end

  describe 'household validation' do
    let!(:household_id) { Hmis::Hud::Base.generate_uuid }
    let!(:hoh_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client1, household_id: household_id, relationship_to_hoh: 1) }
    let!(:hhm_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client2, household_id: household_id, relationship_to_hoh: 2) }

    it 'allows transfer when all household members are included' do
      expect do
        described_class.perform_now(
          enrollment_ids: [hoh_enrollment.id, hhm_enrollment.id],
          source_project_id: source_project.id,
          target_project_id: target_project.id,
        )
      end.not_to raise_error

      hoh_enrollment.reload
      hhm_enrollment.reload
      expect(hoh_enrollment.project_pk).to eq(target_project.id)
      expect(hhm_enrollment.project_pk).to eq(target_project.id)
    end

    it 'raises error when trying to transfer partial household' do
      expect do
        described_class.perform_now(
          enrollment_ids: [hoh_enrollment.id], # Only transferring HoH, not household member
          source_project_id: source_project.id,
          target_project_id: target_project.id,
        )
      end.to raise_error(/Cannot transfer partial household/)
    end

    it 'raises error when trying to transfer only household member without HoH' do
      expect do
        described_class.perform_now(
          enrollment_ids: [hhm_enrollment.id], # Only transferring household member, not HoH
          source_project_id: source_project.id,
          target_project_id: target_project.id,
        )
      end.to raise_error(/Cannot transfer partial household/)
    end

    context 'with household member in different project' do
      let!(:other_project) { create(:hmis_hud_project, data_source: data_source, organization: organization) }
      let!(:hhm_in_other_project) { create(:hmis_hud_enrollment, data_source: data_source, project: other_project, client: client2, household_id: household_id, relationship_to_hoh: 2) }

      it 'only considers household members in the source project' do
        # Should succeed because the household member in the other project doesn't need to be transferred
        expect do
          described_class.perform_now(
            enrollment_ids: [hoh_enrollment.id],
            source_project_id: source_project.id,
            target_project_id: target_project.id,
          )
        end.to raise_error(/Cannot transfer partial household/)
      end
    end
  end
end
