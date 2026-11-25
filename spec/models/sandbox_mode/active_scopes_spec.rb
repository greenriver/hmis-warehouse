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

  [
    GrdaWarehouse::RemoteConfig,
    GrdaWarehouse::HmisImportConfig,
    GrdaWarehouse::CustomImports::Config,
    GrdaWarehouse::EtoApiConfig,
    Health::ImportConfig,
    TextMessage::Topic,
  ].each do |model|
    it "#{model.name}.active is empty by construction only in sandbox mode" do
      expect(model.active.null_relation?).to eq(false)

      with_sandbox_mode do
        expect(model.active.null_relation?).to eq(true)
      end
    end
  end
end
