###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::AuditsController, type: :request do
  let!(:user) { create :acl_user }
  let!(:source_client) { create :authoritative_hud_client }
  let!(:client) { create :fixed_destination_client }
  let!(:warehouse_client) { create :warehouse_client, source: source_client, destination: client }
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

  before(:all) do
    GrdaWarehouse::Utility.clear!
  end

  before do
    sign_in user
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

  it 'omits the table for a client that was never restricted' do
    DestinationClientRestriction.new(other_client).restrict!(user: user)

    get client_audits_path(client)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Access History')
    expect(Nokogiri::HTML(response.body).css('#restriction-history')).to be_empty
    expect(response.body).not_to include('Restriction History')
  end
end
