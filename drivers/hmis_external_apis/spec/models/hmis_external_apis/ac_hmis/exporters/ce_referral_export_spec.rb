# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CeReferralExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:target_project) { create(:hmis_hud_project, data_source: ds) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:app_user) { create(:hmis_user, data_source: ds) }
  let!(:hud_user) { create(:hmis_hud_user, data_source: ds, user_email: app_user.email.downcase) }

  let!(:source_project) { create(:hmis_hud_project, data_source: ds) }
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: client, project: source_project) }
  let!(:custom_status) { create(:hmis_ce_custom_referral_status, key: 'my_custom_status', data_source: ds) }

  let!(:referral) do
    create(
      :hmis_ce_referral,
      data_source: ds,
      project: target_project,
      client: client,
      referred_by: app_user,
      custom_status: custom_status,
    ).tap do |r|
      r.update!(source_enrollment: source_enrollment, completed_at: Time.current)
    end
  end

  let(:subject) { described_class.new }

  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets referrals' do
    subject.run!
    expect(subject.send(:referrals).length).to eq(1)
  end

  it 'makes a csv with expected values' do
    subject.run!
    result = CSV.parse(output, headers: true)

    expect(result.length).to eq(1)
    row = result.first

    expect(row['ReferralID']).to eq(referral.id.to_s)
    expect(row['ReferralWorkflowIdentifier']).to eq(referral.workflow_template.identifier)
    expect(row['PersonalID']).to eq(client.warehouse_id.to_s)
    expect(row['UnitID']).to eq(referral.opportunity.unit.id.to_s)
    expect(row['TargetProjectID']).to eq(target_project.id.to_s)
    expect(row['TargetProjectName']).to eq(target_project.project_name)
    expect(row['ReferralStatus']).to eq(referral.custom_status.key)
    expect(row['ReferredByUserID']).to eq(hud_user.id.to_s)
    expect(row['SourceEnrollmentID']).to eq(source_enrollment.id.to_s)
    expect(row['SourceProjectID']).to eq(source_project.id.to_s)
  end
end
