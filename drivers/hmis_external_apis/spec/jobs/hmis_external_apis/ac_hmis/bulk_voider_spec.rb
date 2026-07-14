###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::BulkVoider, type: :job do
  let!(:data_source) { create(:hmis_primary_data_source) }
  let!(:ce_project) { create(:hmis_hud_project, data_source: data_source, project_type: 14) }
  let!(:void_definition) do
    create(
      :hmis_form_definition,
      identifier: HmisExternalApis::AcHmis::BulkVoider::VOID_FORM_IDENTIFIER,
      role: :CUSTOM_ASSESSMENT,
      status: Hmis::Form::Definition::PUBLISHED,
      data_source: data_source,
      generate_cdeds: true,
      definition: {
        item: [
          { type: 'DATE', link_id: 'linkid_date', required: true, text: 'Assessment Date', assessment_date: true, mapping: { field_name: 'assessmentDate' } },
          { type: 'BOOLEAN', link_id: 'void_all_referrals', required: true, text: 'Void All Referrals', mapping: { custom_field_key: 'void_assessment_void_all_referrals' } },
          { type: 'STRING', link_id: 'void_reason', required: true, text: 'Reason for Voiding', mapping: { custom_field_key: 'void_assessment_void_reason' } },
        ],
      },
    )
  end
  # Form definition factory created the CDEDs; find them by key
  let(:void_cded) { Hmis::Hud::CustomDataElementDefinition.find_by(key: 'void_assessment_void_all_referrals') }
  let(:void_reason_cded) { Hmis::Hud::CustomDataElementDefinition.find_by(key: 'void_assessment_void_reason') }

  def perform_bulk_void(destination_client_ids, ce_project_id: ce_project.id, initiated_by_id: nil)
    described_class.new.perform(
      destination_client_ids: destination_client_ids,
      ce_project_id: ce_project_id,
      initiated_by_id: initiated_by_id,
      dry_run: false,
    )
  end

  describe '#perform' do
    let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
    let!(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: client) }
    let(:initiated_by) { create(:hmis_user, data_source: data_source) }

    it 'creates exit and void assessment for client with open CE enrollment' do
      expect do
        perform_bulk_void([client.warehouse_id])
      end.to change(Hmis::Hud::Exit, :count).by(1).
        and change(Hmis::Hud::CustomAssessment, :count).by(2) # exit assessment + void assessment

      enrollment.reload
      expect(enrollment.exit).to be_present
      expect(enrollment.exit.exit_date).to eq(Date.current)
      expect(enrollment.exit.destination).to eq(::HudHelper.util.destination_no_exit_interview_completed)

      exit_assessment = Hmis::Hud::CustomAssessment.where(enrollment_id: enrollment.enrollment_id, data_collection_stage: 3).sole
      expect(exit_assessment.created_by_hud_user).to eq(Hmis::Hud::User.system_user(data_source_id: data_source.id))
      expect(exit_assessment.updated_by_hud_user).to eq(Hmis::Hud::User.system_user(data_source_id: data_source.id))

      void_assessment = Hmis::Hud::CustomAssessment.where(enrollment_id: enrollment.enrollment_id, data_collection_stage: 99).sole
      expect(void_assessment.custom_data_elements.count).to eq(2)
      expect(void_assessment.custom_data_elements.find_by(data_element_definition: void_cded).value_boolean).to eq(true)
      expect(void_assessment.custom_data_elements.find_by(data_element_definition: void_reason_cded).value_string).
        to include('CE Waitlist Management Process')
      expect(void_assessment.created_by_hud_user).to eq(Hmis::Hud::User.system_user(data_source_id: data_source.id))
      expect(void_assessment.updated_by_hud_user).to eq(Hmis::Hud::User.system_user(data_source_id: data_source.id))
    end

    context 'when client is already exited' do
      let!(:exited_client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
      let(:exit_date) { 1.week.ago.to_date }
      let!(:older_exited_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: exited_client, exit_date: 2.weeks.ago) }
      let!(:exited_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: exited_client, exit_date: exit_date) }

      it 'creates void assessment for the most recently exited enrollment without creating a new exit' do
        expect do
          perform_bulk_void([client.warehouse_id, exited_client.warehouse_id])
        end.to change(Hmis::Hud::Exit, :count).by(1).
          and change(Hmis::Hud::CustomAssessment.where(data_collection_stage: 99), :count).by(2).
          and(not_change { Hmis::Hud::Exit.where(enrollment_id: exited_enrollment.enrollment_id, data_source_id: data_source.id).count })

        expect(exited_enrollment.reload.custom_assessments.where(data_collection_stage: 99).count).to eq(1)
        expect(older_exited_enrollment.reload.custom_assessments.where(data_collection_stage: 99).count).to eq(0)
        expect(exited_enrollment.exit.exit_date).to eq(exit_date)
      end
    end

    context 'when a client has both an open and an exited CE enrollment' do
      let!(:exited_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: client, exit_date: 1.week.ago) }

      it 'processes only the open enrollment and leaves the exited one untouched' do
        expect do
          perform_bulk_void([client.warehouse_id])
        end.to change(Hmis::Hud::Exit, :count).by(1). # only the open enrollment gets a new exit
          and change(Hmis::Hud::CustomAssessment.where(data_collection_stage: 99), :count).by(1)

        expect(enrollment.reload.exit).to be_present
        expect(enrollment.custom_assessments.where(data_collection_stage: 99).count).to eq(1)
        # The already-exited enrollment is not double-processed, since the client is handled via the open path
        expect(exited_enrollment.reload.custom_assessments.where(data_collection_stage: 99).count).to eq(0)
      end
    end

    it 'is idempotent - re-running does not create duplicate void assessments or exits' do
      perform_bulk_void([client.warehouse_id])

      # On the second run the enrollment is already exited, so it takes the exited path,
      # which skips creating a Void Assessment because one already exists.
      expect do
        perform_bulk_void([client.warehouse_id])
      end.to not_change(Hmis::Hud::Exit, :count).
        and not_change(Hmis::Hud::CustomAssessment.where(data_collection_stage: 99), :count)

      expect(enrollment.reload.custom_assessments.where(data_collection_stage: 99).count).to eq(1)
    end

    it 'tracks PaperTrail metadata for void assessments created on already-exited enrollments' do
      exited_client = create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
      exited_enrollment = create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: exited_client, exit_date: 1.week.ago)

      run_id = '00000000-0000-0000-0000-000000000002'
      allow(SecureRandom).to receive(:uuid).and_return(run_id)

      PaperTrailHelper.with_paper_trail do
        PaperTrail.request.enabled = true
        perform_bulk_void([exited_client.warehouse_id], initiated_by_id: initiated_by.id)
      end

      versions = GrdaWarehouse.paper_trail_versions.where(request_id: run_id)
      expect(versions.where(item_type: 'Hmis::Hud::CustomAssessment', enrollment_id: exited_enrollment.id)).to exist
      expect(versions.pluck(:whodunnit).uniq).to eq([initiated_by.id.to_s])
    end

    describe 'project validation guard' do
      it 'refuses to process a non-Coordinated-Entry project and makes no changes' do
        non_ce_project = create(:hmis_hud_project, data_source: data_source, project_type: 1)

        expect do
          expect do
            perform_bulk_void([client.warehouse_id], ce_project_id: non_ce_project.id)
          end.to raise_error(ActiveRecord::RecordNotFound)
        end.to not_change(Hmis::Hud::Exit, :count).
          and not_change(Hmis::Hud::CustomAssessment, :count)
      end

      it 'refuses to process a closed CE project and makes no changes' do
        closed_ce_project = create(:hmis_hud_project, data_source: data_source, project_type: 14, operating_end_date: 1.week.ago.to_date)

        expect do
          expect do
            perform_bulk_void([client.warehouse_id], ce_project_id: closed_ce_project.id)
          end.to raise_error(ActiveRecord::RecordNotFound)
        end.to not_change(Hmis::Hud::Exit, :count).
          and not_change(Hmis::Hud::CustomAssessment, :count)
      end
    end
    
    it 'tracks PaperTrail metadata for created records' do
      run_id = '00000000-0000-0000-0000-000000000001'

      allow(SecureRandom).to receive(:uuid).and_return(run_id)

      PaperTrailHelper.with_paper_trail do
        PaperTrail.request.enabled = true
        perform_bulk_void([client.warehouse_id], initiated_by_id: initiated_by.id)
      end

      versions = GrdaWarehouse.paper_trail_versions.where(request_id: run_id)
      expect(versions).not_to be_empty
      expect(versions.pluck(:whodunnit).uniq).to eq([initiated_by.id.to_s])
      expect(versions.pluck(:user_id).uniq).to eq([initiated_by.id])
      expect(versions.pluck(:true_user_id).uniq).to eq([initiated_by.id])
      expect(versions.where(item_type: 'Hmis::Hud::CustomAssessment', enrollment_id: enrollment.id)).to exist
      expect(versions.where(item_type: 'Hmis::Hud::Exit', enrollment_id: enrollment.id)).to exist
    end

    context 'when there are multiple household members' do
      let!(:spouse) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
      let!(:spouse_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: spouse, household_id: enrollment.household_id, relationship_to_hoh: 3) }
      let!(:child) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
      let!(:child_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: child, household_id: enrollment.household_id, relationship_to_hoh: 2) }

      it 'exits all household members and creates void assessment only for the requested client' do
        expect do
          perform_bulk_void([client.warehouse_id])
          [enrollment, spouse_enrollment, child_enrollment].each(&:reload)
        end.to change(Hmis::Hud::Exit, :count).by(3).
          and change(Hmis::Hud::CustomAssessment.where(data_collection_stage: 99), :count).by(1)

        expect(enrollment.exit).to be_present
        expect(spouse_enrollment.exit).to be_present
        expect(child_enrollment.exit).to be_present

        void_assessment = Hmis::Hud::CustomAssessment.where(enrollment_id: enrollment.enrollment_id, data_collection_stage: 99).sole
        expect(void_assessment.custom_data_elements.count).to eq(2)
        expect(void_assessment.custom_data_elements.find_by(data_element_definition: void_cded).value_boolean).to eq(true)
        expect(void_assessment.custom_data_elements.find_by(data_element_definition: void_reason_cded).value_string).
          to include('CE Waitlist Management Process')

        expect(spouse_enrollment.custom_assessments.where(data_collection_stage: 99).count).to eq(0)
        expect(child_enrollment.custom_assessments.where(data_collection_stage: 99).count).to eq(0)
      end

      context 'when there is an incomplete intake for a hhm' do
        let!(:other_hhm) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
        let!(:other_hhm_enrollment) { create(:hmis_hud_wip_enrollment, data_source: data_source, project: ce_project, client: other_hhm, household_id: enrollment.household_id, relationship_to_hoh: 2) }

        let!(:unrelated) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
        let!(:unrelated_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: unrelated) }

        it 'does not exit or void any of the enrollments' do
          expect do
            perform_bulk_void([client.warehouse_id, unrelated.warehouse_id])
          end.to change(Hmis::Hud::Exit, :count).by(1).
            and change(Hmis::Hud::CustomAssessment.where(data_collection_stage: 99), :count).by(1)

          expect(enrollment.reload.exit).not_to be_present
          expect(spouse_enrollment.reload.exit).not_to be_present
          expect(child_enrollment.reload.exit).not_to be_present
          expect(other_hhm_enrollment.reload.exit).not_to be_present

          # Only the unrelated enrollment is exited
          expect(unrelated_enrollment.reload.exit).to be_present
        end
      end
    end

    describe 'with dry_run: true' do
      it 'does not create exits or void assessments' do
        expect do
          described_class.new.perform(destination_client_ids: [client.warehouse_id], ce_project_id: ce_project.id, dry_run: true)
        end.to not_change(Hmis::Hud::Exit, :count).
          and not_change(Hmis::Hud::CustomAssessment, :count)
      end
    end
  end
end
