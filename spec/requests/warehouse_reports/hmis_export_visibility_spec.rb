###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HMIS export visibility', type: :request do
  include AccessControlSetup

  let(:collection) { create(:collection) }
  let(:full_report) { create(:hmis_export_report) }
  let(:hashed_report) { create(:hmis_export_report, url: 'warehouse_reports/hashed_only_hmis_exports', name: 'HUD HMIS CSV Exports (Hashed Only)') }
  let(:own_exports_user) { user_with_role(can_export_hmis_data: true, can_view_assigned_reports: true) }
  let(:all_reports_user) { user_with_role(can_export_hmis_data: true, can_view_assigned_reports: true, can_view_all_reports: true) }

  let!(:own_export) { create(:grda_warehouse_hmis_export, :with_zip, user_id: own_exports_user.id) }
  let!(:others_export) { create(:grda_warehouse_hmis_export, :with_zip, user_id: all_reports_user.id) }

  # Permission lookups are cached in Rails.cache, which outlives each example's transaction.
  before do
    Rails.cache.clear
    collection.set_viewables({ reports: [full_report.id, hashed_report.id] })
  end

  describe 'HUD HMIS CSV Exports' do
    context 'as a user who sees only their own exports' do
      before { sign_in(own_exports_user) }

      it 'downloads an export the user ran' do
        get warehouse_reports_hmis_export_path(own_export)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('zip-data')
      end

      it 'returns not found when downloading an export run by another user' do
        get warehouse_reports_hmis_export_path(others_export)

        expect(response).to have_http_status(:not_found)
        expect(response.media_type).not_to eq('application/zip')
      end

      it 'deletes an export the user ran' do
        delete warehouse_reports_hmis_export_path(own_export)

        expect(GrdaWarehouse::HmisExport.where(id: own_export.id)).not_to exist
      end

      it 'returns not found and keeps the export when deleting one run by another user' do
        delete warehouse_reports_hmis_export_path(others_export)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::HmisExport.where(id: others_export.id)).to exist
      end

      context "with another user's recurring export" do
        let!(:recurring_export) { create(:recurring_hmis_export, user: all_reports_user, every_n_days: 7) }

        before { create(:recurring_hmis_export_link, recurring_hmis_export: recurring_export, hmis_export: others_export) }

        it 'returns not found when editing it' do
          get edit_warehouse_reports_hmis_export_path(others_export)

          expect(response).to have_http_status(:not_found)
        end

        it 'returns not found and leaves it unchanged when updating it' do
          patch warehouse_reports_hmis_export_path(others_export), params: { filter: { every_n_days: 1, reporting_range: 'fixed' } }

          expect(response).to have_http_status(:not_found)
          expect(recurring_export.reload.every_n_days).to eq(7)
        end

        it 'returns not found and keeps it when cancelling it' do
          delete cancel_warehouse_reports_hmis_export_path(others_export)

          expect(response).to have_http_status(:not_found)
          expect(GrdaWarehouse::RecurringHmisExport.where(id: recurring_export.id)).to exist
        end
      end
    end

    it 'downloads an export run by another user for a user who can view all reports' do
      sign_in(all_reports_user)
      get warehouse_reports_hmis_export_path(own_export)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('zip-data')
    end
  end

  describe 'HUD HMIS CSV Exports (Hashed Only)' do
    let!(:own_hashed_export) { create(:grda_warehouse_hmis_export, :with_zip, user_id: own_exports_user.id, hash_status: 4) }

    before { sign_in(own_exports_user) }

    it 'downloads a hashed export the user ran' do
      get warehouse_reports_hashed_only_hmis_export_path(own_hashed_export)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('zip-data')
    end

    it 'returns not found when downloading an unhashed export the user ran' do
      get warehouse_reports_hashed_only_hmis_export_path(own_export)

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).not_to eq('application/zip')
    end

    it 'returns not found when downloading a hashed export run by another user' do
      others_hashed_export = create(:grda_warehouse_hmis_export, :with_zip, user_id: all_reports_user.id, hash_status: 4)

      get warehouse_reports_hashed_only_hmis_export_path(others_hashed_export)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found and keeps the export when deleting an unhashed export' do
      delete warehouse_reports_hashed_only_hmis_export_path(own_export)

      expect(response).to have_http_status(:not_found)
      expect(GrdaWarehouse::HmisExport.where(id: own_export.id)).to exist
    end
  end

  # setup_access_control names the user group from the role name and collection, so
  # roles sharing a name would put every user in one group with all their permissions.
  def user_with_role(**permissions)
    user = create(:acl_user)
    setup_access_control(user, create(:role, name: "role #{permissions.inspect}", **permissions), collection)
    user
  end
end
