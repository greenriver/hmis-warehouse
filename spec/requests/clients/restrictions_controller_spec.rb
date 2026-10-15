###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::RestrictionsController, type: :request do
  let!(:user) { create :acl_user }
  let!(:source_client) { create :authoritative_hud_client }
  let!(:client) { create :fixed_destination_client }
  let!(:warehouse_client) { create :warehouse_client, source: source_client, destination: client }
  let!(:project) { create :grda_warehouse_hud_project, data_source_id: source_client.data_source_id }
  let!(:enrollment) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
      ProjectID: project.ProjectID,
      EntryDate: 1.month.ago.to_date,
    )
  end
  let(:project_collection) { create(:collection).tap { |collection| collection.add_viewable(project) } }
  let(:marking_role) { create(:role, can_view_clients: true, can_view_client_name: true, can_view_full_client_dashboard: true, can_mark_clients_as_restricted: true) }
  let(:viewing_role) { create(:role, can_view_clients: true, can_view_client_name: true, can_view_full_client_dashboard: true) }

  def warehouse_rows
    Hmis::RestrictedRecord.for_clients.where(restrictable_id: client.id)
  end

  before(:all) do
    GrdaWarehouse::Utility.clear!
  end

  before { sign_in user }

  def restriction_badge
    Nokogiri::HTML(response.body).css('#restriction-flag span.badge').map { |el| el.text.strip }
  end

  context 'with the permission' do
    before { setup_access_control(user, marking_role, project_collection) }

    it 'restricts the destination client and returns to the dashboard' do
      patch client_restriction_path(client), params: { restricted: '1' }
      expect(warehouse_rows.pluck(:created_by_id)).to eq([user.id])
      expect(response).to redirect_to(client_path(client))
    end

    it 'removes the warehouse restriction' do
      DestinationClientRestriction.new(client).restrict!(user: user)
      patch client_restriction_path(client), params: { restricted: '0' }
      expect(warehouse_rows.count).to eq(0)
    end

    it 'keeps an HMIS restriction and says so when unrestricting' do
      Hmis::RestrictedRecord.create!(
        restrictable_id: source_client.id,
        restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
        data_source_id: source_client.data_source_id,
        created_by: Hmis::User.find(user.id),
      )
      patch client_restriction_path(client), params: { restricted: '0' }
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: source_client.id).count).to eq(1)
      expect(flash[:notice]).to eq('Warehouse restriction removed. This client is still restricted in HMIS and can only be unrestricted there.')
    end

    it 'shows the restrict button on the dashboard and the form in the modal' do
      get client_path(client)
      expect(response.body).to include(client_restriction_path(client))
      get client_restriction_path(client)
      expect(response.body).to include('Restrict Client')
    end
  end

  context 'without the permission' do
    before { setup_access_control(user, viewing_role, project_collection) }

    it 'does not restrict the client' do
      patch client_restriction_path(client), params: { restricted: '1' }
      expect(warehouse_rows.count).to eq(0)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'does not remove an existing restriction' do
      DestinationClientRestriction.new(client).restrict!(user: user)
      patch client_restriction_path(client), params: { restricted: '0' }
      expect(warehouse_rows.count).to eq(1)
    end

    it 'shows the Restricted badge but no button on the dashboard' do
      DestinationClientRestriction.new(client).restrict!(user: user)
      get client_path(client)
      expect(restriction_badge).to eq(['Restricted'])
      expect(response.body).not_to include(client_restriction_path(client))
    end
  end
end
