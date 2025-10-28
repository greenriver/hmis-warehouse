###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CeReferralTaskExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:target_project) { create(:hmis_hud_project, data_source: ds) }

  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds) }
  let!(:instance) { create(:hmis_workflow_execution_instance, template: workflow_template) }
  let!(:node) { create(:hmis_workflow_definition_user_task, template: workflow_template) }

  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:app_user) { create(:hmis_user, data_source: ds) }
  let!(:hud_user) { create(:hmis_hud_user, data_source: ds, user_email: app_user.email.downcase) }

  let!(:referral) do
    create(
      :hmis_ce_referral,
      data_source: ds,
      project: target_project,
      client: client,
      workflow_instance: instance,
      referred_by: app_user,
    )
  end

  let!(:step) do
    create(
      :hmis_wfe_step,
      instance: instance,
      node: node,
      status: 'completed',
    ).tap do |s|
      s.update!(updated_by: app_user, completed_at: Time.current)
    end
  end

  let(:subject) { described_class.new }

  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets referral tasks' do
    subject.run!
    expect(subject.send(:referral_tasks).length).to eq(1)
  end

  it 'makes a csv with expected values' do
    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)

    row = result.first
    expect(row['TaskID']).to eq(step.id.to_s)
    expect(row['ReferralID']).to eq(referral.id.to_s)
    expect(row['ReferralWorkflowIdentifier']).to eq(workflow_template.identifier)
    expect(row['NodeID']).to eq(node.id.to_s)
    expect(row['NodeName']).to eq(node.name)
    expect(row['Status']).to eq(step.status)
    expect(row['UpdatedByUserID']).to eq(hud_user.id.to_s)
  end

  context 'when a client with a referral has been deleted' do
    before do
      client.destroy!
    end

    it 'succeeds' do
      subject.run!
      result = CSV.parse(output, headers: true)
      expect(result.length).to eq(0)
    end
  end
end
