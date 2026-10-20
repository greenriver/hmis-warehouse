###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::AuditsController, type: :request do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  let!(:user) { create :acl_user }
  let!(:source_client) { create :authoritative_hud_client }
  let!(:client) { create :fixed_destination_client }
  let!(:warehouse_client) { create :warehouse_client, source: source_client, destination: client }
  let!(:no_data_source_collection) { create :collection }

  def log(path:, title:, item_model: 'GrdaWarehouse::Hud::Client')
    ActivityLog.create!(
      user: user,
      path: path,
      title: title,
      item_model: item_model,
      controller_name: 'clients',
      action_name: 'show',
      ip_address: '127.0.0.1',
    )
  end

  before do
    sign_in user
    Collection.maintain_system_groups
  end

  describe 'GET #index' do
    context 'with can_audit_clients' do
      before do
        setup_access_control(user, create(:admin_role, can_audit_clients: true), Collection.system_collection(:data_sources))
      end

      it "lists only this client's access, excluding source-client and id-prefix paths" do
        log(path: "/clients/#{client.id}/history", title: 'Own history visit')
        log(path: "/clients/#{client.id}?tab=x", title: 'Own query-string visit')
        log(path: "/source_clients/#{client.id}/edit", title: 'Source client visit')
        log(path: "/clients/#{client.id}0/history", title: 'Other client visit')
        log(path: "/clients/#{client.id}/history", title: 'Non-client item visit', item_model: nil)

        get client_audits_path(client)

        titles = Nokogiri::HTML(response.body).css('table tbody tr td:last-child a').map { |a| a.text.strip }
        expect(titles).to contain_exactly('Own history visit', 'Own query-string visit')
      end
    end

    context 'without can_audit_clients' do
      before do
        setup_access_control(user, create(:admin_role), Collection.system_collection(:data_sources))
      end

      it 'does not render the access history' do
        log(path: "/clients/#{client.id}/history", title: 'Own history visit')

        get client_audits_path(client)

        expect(response).to have_http_status(:redirect)
        expect(response.body).not_to include('Own history visit')
      end
    end
  end
end
