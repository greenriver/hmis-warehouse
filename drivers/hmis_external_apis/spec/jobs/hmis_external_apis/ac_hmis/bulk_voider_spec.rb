###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  def perform_bulk_void(destination_client_ids)
    described_class.new.perform(
      destination_client_ids: destination_client_ids,
      ce_project_id: ce_project.id,
      dry_run: false,
    )
  end

  describe '#perform' do
    let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
    let!(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: client) }

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
      let!(:exited_enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, client: exited_client, exit_date: Date.current) }

      it 'does not create void assessment for the exited client' do
        expect do
          perform_bulk_void([client.warehouse_id, exited_client.warehouse_id])
        end.to change(Hmis::Hud::Exit, :count).by(1).
          and change(Hmis::Hud::CustomAssessment.where(data_collection_stage: 99), :count).by(1)

        # No void assessment was created for the already exited client
        expect(exited_enrollment.reload.custom_assessments.where(data_collection_stage: 99).count).to eq(0)
      end
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
