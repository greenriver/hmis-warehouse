###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::ReleasesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source) }
  let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
  let!(:file) do
    create :client_file, client: client, tags: [consent_tag], effective_date: 5.days.ago, expiration_date: 1.year.from_now.to_date
  end

  before do
    GrdaWarehouse::Config.delete_all
    create :config_b, roi_model: :explicit, release_duration: 'Indefinite'
    GrdaWarehouse::Config.invalidate_cache

    sign_in user
    setup_access_control(user, create(:role, can_manage_client_files: true, can_confirm_housing_release: true, can_use_separated_consent: true), create(:collection))
    allow_any_instance_of(Clients::ReleasesController).to receive(:destination_searchable_client_scope).and_return(
      GrdaWarehouse::Hud::Client.where(id: client.id),
    )
    allow_any_instance_of(GrdaWarehouse::ClientFile).to receive(:file_exists_and_not_too_large).and_return(true)
    file.confirm_consent!
  end

  def roi_row
    GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
  end

  def revoke(extra_params = {})
    patch client_release_path(client_id: client.id, id: file.id),
          params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s }.merge(extra_params) },
          xhr: true
  end

  describe 'PATCH #update' do
    it 'clears the release and removes the ROI row when the consent form is revoked' do
      expect(roi_row.status).to eq('full')

      revoke

      expect(file.reload.consent_revoked_at.to_date).to eq(Date.current)
      expect(client.reload.housing_release_status).to be_nil
      expect(roi_row).to be_nil
    end

    it 'keeps the release and the ROI row when the revoked file fails validation' do
      revoke(visible_in_window: '')

      expect(file.reload.consent_revoked_at).to be_nil
      expect(client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
      expect(roi_row.status).to eq('full')
    end
  end
end
