###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The PDF partial renders inside a background DocumentExport as the export's user, so it is
# rendered directly here with that user as current_user.
RSpec.describe 'warehouse_reports/client_details/actives/_pdf_table', type: :view do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_projects: true, can_view_client_name: true, can_view_clients: true) }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
    end
  end

  it 'renders every client when more clients than the preload miss threshold are in the batch' do
    clients = Array.new(preload_miss_client_count) do |i|
      source = create(:hmis_hud_client, data_source: hmis_ds, first_name: "Preload#{i}", last_name: 'Coverage')
      destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{i}", LastName: 'Coverage')
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: hmis_ds.id, id_in_source: source.id.to_s)
      create(:she_entry, client: destination, project: project, record_type: :entry, project_type: 1, first_date_in_program: 1.year.ago.to_date, last_date_in_program: nil)
      destination
    end
    assign(:batch, GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: clients.map(&:id)).preload(:client, :project))

    render partial: 'warehouse_reports/client_details/actives/pdf_table'

    clients.each { |client| expect(rendered).to include(client.FirstName) }
  end
end
