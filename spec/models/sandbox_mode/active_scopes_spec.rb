###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SandboxMode gating of active scopes', type: :model do
  it 'hides an active remote credential only in sandbox mode' do
    active = create(:grda_remote_s3, active: true, slug: 'app_stats')
    create(:grda_remote_s3, active: false)

    expect(GrdaWarehouse::RemoteCredential.active).to contain_exactly(active)
    expect(GrdaWarehouse::RemoteCredentials::S3.for_active_slug('app_stats')).to eq(active)

    with_sandbox_mode do
      expect(GrdaWarehouse::RemoteCredential.active).to be_empty
      expect(GrdaWarehouse::RemoteCredentials::S3.for_active_slug('app_stats')).to be_nil
    end
  end

  {
    GrdaWarehouse::RemoteConfig => ->(active) { GrdaWarehouse::RemoteConfig.create!(type: 'GrdaWarehouse::RemoteConfig', active: active, remote_credential: create(:grda_remote_s3)) },
    GrdaWarehouse::HmisImportConfig => ->(active) { create(:grda_warehouse_hmis_import_config, active: active) },
    GrdaWarehouse::CustomImports::Config => ->(active) { GrdaWarehouse::CustomImports::Config.create!(user: create(:user), active: active, data_source: create(:source_data_source)) },
    GrdaWarehouse::EtoApiConfig => ->(active) { GrdaWarehouse::EtoApiConfig.create!(email: 'someone@partner.example', password: 'secret', active: active, data_source: create(:source_data_source)) },
    Health::ImportConfig => ->(active) { Health::ImportConfig.create!(active: active, host: 'sftp.partner.example', username: 'someone', password: 'secret') },
    TextMessage::Topic => ->(active) { TextMessage::Topic.create!(arn: 'arn:aws:sns:us-east-1:1:topic', active_topic: active) },
  }.each do |model, build_row|
    it "#{model.name}.active returns only active rows, and none in sandbox mode" do
      active_row = instance_exec(true, &build_row)
      instance_exec(false, &build_row)

      expect(model.active).to contain_exactly(active_row)

      with_sandbox_mode do
        expect(model.active).to be_empty
      end
    end
  end
end
