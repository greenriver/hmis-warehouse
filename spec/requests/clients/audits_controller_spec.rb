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
  end

  describe 'GET #index' do
    before do
      Collection.maintain_system_groups
    end

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

  describe 'restriction history' do
    let!(:other_client) { create :fixed_destination_client, id: 102 }
    let!(:other_warehouse_client) { create :warehouse_client, source: create(:authoritative_hud_client), destination: other_client }
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
    let(:role) do
      create(
        :role,
        can_view_clients: true,
        can_view_client_name: true,
        can_view_full_client_dashboard: true,
        can_search_own_clients: true,
        can_audit_clients: true,
        can_mark_clients_as_restricted: true,
      )
    end

    around do |example|
      PaperTrail.enabled = true
      example.run
    ensure
      PaperTrail.enabled = false
    end

    before do
      setup_access_control(user, role, project_collection)
    end

    def restriction_rows
      Nokogiri::HTML(response.body).css('#restriction-history tbody tr').map do |tr|
        tr.css('td').drop(1).map { |td| td.text.strip } # drop the date column
      end
    end

    it 'lists warehouse and HMIS restriction changes for a restricted client, attributed to the acting user' do
      PaperTrail.request(whodunnit: user.id.to_s) do
        Hmis::RestrictedRecord.create!(
          restrictable_id: source_client.id,
          restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
          data_source_id: source_client.data_source_id,
          created_by: Hmis::User.find(user.id),
        )
      end
      patch client_restriction_path(client), params: { restricted: '1' }
      patch client_restriction_path(client), params: { restricted: '0' }
      DestinationClientRestriction.new(other_client).restrict!(user: user)

      get client_audits_path(client)

      expect(response).to have_http_status(:ok)
      expect(restriction_rows).to eq(
        [
          [user.name, 'Restricted: Yes → No', 'Warehouse'],
          [user.name, 'Restricted: No → Yes', 'Warehouse'],
          [user.name, 'Restricted: No → Yes', 'HMIS'],
        ],
      )
    end

    it 'keeps the table for a client restricted and then unrestricted' do
      patch client_restriction_path(client), params: { restricted: '1' }
      patch client_restriction_path(client), params: { restricted: '0' }

      get client_audits_path(client)

      expect(restriction_rows).to eq(
        [
          [user.name, 'Restricted: Yes → No', 'Warehouse'],
          [user.name, 'Restricted: No → Yes', 'Warehouse'],
        ],
      )
    end

    it 'names a user who has since been deleted' do
      deleted_user = create(:user)
      DestinationClientRestriction.new(client).restrict!(user: deleted_user)
      deleted_user.destroy!

      get client_audits_path(client)

      expect(restriction_rows).to eq([[deleted_user.name, 'Restricted: No → Yes', 'Warehouse']])
    end

    describe 'access history titles' do
      before do
        ['Jane Doe - Audit', 'Jane Doe'].each_with_index do |title, i|
          ActivityLog.create!(
            user_id: user.id,
            item_model: 'GrdaWarehouse::Hud::Client',
            item_id: client.id,
            controller_name: 'clients',
            action_name: 'show',
            ip_address: '127.0.0.1',
            path: "/clients/#{client.id}",
            title: title,
            created_at: i.minutes.ago,
          )
        end
      end

      def access_history_items
        Nokogiri::HTML(response.body).css('table').first.css('tbody tr').map { |tr| tr.css('td').last.text.strip }
      end

      it 'hides the name logged before the client was restricted, keeping the page label' do
        DestinationClientRestriction.new(client).restrict!(user: user)

        get client_audits_path(client)

        expect(access_history_items).to eq(['Name Redacted - Audit', 'Name Redacted'])
      end

      it 'hides the logged name when only a source client is restricted in HMIS' do
        Hmis::RestrictedRecord.create!(
          restrictable_id: source_client.id,
          restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
          data_source_id: source_client.data_source_id,
          created_by: Hmis::User.find(user.id),
        )

        get client_audits_path(client)

        expect(access_history_items).to eq(['Name Redacted - Audit', 'Name Redacted'])
      end

      it 'shows the logged name for an unrestricted client' do
        get client_audits_path(client)

        expect(access_history_items).to eq(['Jane Doe - Audit', 'Jane Doe'])
      end
    end

    it 'omits the table for a client that was never restricted' do
      DestinationClientRestriction.new(other_client).restrict!(user: user)

      get client_audits_path(client)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Access History')
      expect(Nokogiri::HTML(response.body).css('#restriction-history')).to be_empty
      expect(response.body).not_to include('Restriction History')
    end
  end
end
