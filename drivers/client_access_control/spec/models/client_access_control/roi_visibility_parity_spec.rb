###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Every ACL check that can expose a client through an ROI must agree for the same fixtures.
RSpec.describe 'ROI visibility parity', type: :model do
  let(:data_source) { create :source_data_source }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }
  let!(:source_client) { create :hud_client, data_source: data_source }
  let!(:enrollment) { create :hud_enrollment, data_source: data_source, client: source_client, project: project }
  let(:destination_data_source) { create :destination_data_source }
  let!(:destination_client) { create :hud_client, data_source: destination_data_source }
  let!(:warehouse_client) { create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id }

  let(:user) { create :acl_user }
  let(:roi_role) { create :role, can_search_clients_with_roi: true, can_view_client_enrollments_with_roi: true }
  let(:collection) { create :collection }

  before do
    GrdaWarehouse::Config.delete_all
    create(config_factory)
    GrdaWarehouse::Config.invalidate_cache
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, roi_role, collection)
  end

  # update_columns skips the sync hooks, so build the row the way the nightly task does
  def set_release!(status)
    destination_client.update_columns(housing_release_status: status, consented_coc_codes: [])
    GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
  end

  def visibility
    {
      search: GrdaWarehouse::Hud::Client.searchable_to(user).where(id: source_client.id).exists?,
      detail_scope: GrdaWarehouse::Hud::Client.source_visible_to(user).where(id: source_client.id).exists?,
      enrollments: GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: enrollment.id).exists?,
      policy: user.policy_for(source_client).can_view?,
      demographics: destination_client.show_demographics_to?(user),
    }
  end

  def on_every_path(value)
    { search: value, detail_scope: value, enrollments: value, policy: value, demographics: value }
  end

  shared_examples 'shared ROI rules' do
    it 'exposes the client on every path with a full release' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string)
      expect(visibility).to eq(on_every_path(true))
    end

    it 'reads the ROI row, not the client columns, on every path' do
      create(:client_roi_authorization, destination_client: destination_client, status: 'full')
      expect(destination_client.reload.housing_release_status).to be_nil
      expect(visibility).to eq(on_every_path(true))
    end

    it 'hides the client on every path when the source data source does not obey consent' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string)
      data_source.update!(obey_consent: false)
      expect(visibility).to eq(on_every_path(false))
    end

    it 'hides the client on every path immediately after revoking consent' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string)
      destination_client.invalidate_consent!(hr_status: GrdaWarehouse::Config.active_consent_class.revoked_consent_string)
      expect(visibility).to eq(on_every_path(false))
    end

    context 'with a second source client in a data source that does not obey consent' do
      let(:other_data_source) { create :source_data_source, obey_consent: false }
      let(:other_project) { create :grda_warehouse_hud_project, data_source: other_data_source }
      let!(:other_source_client) { create :hud_client, data_source: other_data_source }
      let!(:other_enrollment) { create :hud_enrollment, data_source: other_data_source, client: other_source_client, project: other_project }
      let!(:other_warehouse_client) { create :warehouse_client, source_id: other_source_client.id, destination_id: destination_client.id }

      before { collection.set_viewables({ projects: [project.id, other_project.id] }) }

      it 'exposes only the source client and enrollment from the data source that obeys consent' do
        set_release!(GrdaWarehouse::Hud::Client.full_release_string)
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: [enrollment.id, other_enrollment.id]).pluck(:id)).to contain_exactly(enrollment.id)
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).where(id: [source_client.id, other_source_client.id]).pluck(:id)).to contain_exactly(source_client.id)
        expect(user.policy_for(other_source_client).can_view?).to be false
      end
    end

    context 'with direct can_view_clients access to a data source that does not obey consent' do
      let(:view_role) { create :role, can_view_clients: true, can_search_own_clients: true }

      it 'still exposes the client without any release' do
        data_source.update!(obey_consent: false)
        setup_access_control(user, view_role, collection)
        expect(visibility.except(:demographics)).to eq(on_every_path(true).except(:demographics))
      end
    end
  end

  context 'with Consent::Default' do
    let(:config_factory) { :config_b }

    include_examples 'shared ROI rules'

    it 'hides the client on every path with a partial (CAS-only) release' do
      set_release!(Consent::Default.partial_release_string)
      expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: destination_client.id).status).to eq('partial')
      expect(visibility).to eq(on_every_path(false))
    end
  end

  context 'with Consent::Implied' do
    let(:config_factory) { :config_va }

    include_examples 'shared ROI rules'

    it 'exposes the client on every path with implied consent' do
      set_release!(Consent::Implied.no_release_string)
      expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: destination_client.id).status).to eq('partial')
      expect(visibility).to eq(on_every_path(true))
    end
  end
end
