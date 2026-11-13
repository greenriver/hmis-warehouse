###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

RSpec.describe Clients::FilesController, type: :request do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  let!(:config) { create :config_b, verified_homeless_history_visible_to_all: true }
  let!(:user) { create :acl_user }
  let(:destination) { non_window_destination_client }
  let!(:verified_homeless_tag) { create :available_file_tag, name: 'Homeless Verification', verified_homeless_history: true }
  let!(:history_file) { create :client_file, client: destination, tags: [verified_homeless_tag] }
  let(:base_permissions) { { can_view_clients: true, can_search_own_clients: true, can_view_client_name: true, can_view_full_client_dashboard: true } }
  let(:pdf_permissions) { { can_view_client_history_calendar: true, can_generate_homeless_verification_pdfs: true } }

  before { sign_in user }

  def file_rows
    Nokogiri::HTML(response.body).css(".client-file-#{history_file.id}")
  end

  it 'lists the verification PDF when the role on the client project grants the PDF permission' do
    setup_access_control(user, create(:role, **base_permissions, **pdf_permissions), non_window_project_viewable_collection)

    get client_files_path(client_id: destination.id)

    expect(response).to have_http_status(:ok)
    expect(file_rows.size).to eq(1)
  end

  it 'renders the page without the verification PDF when the PDF permission comes from a project the client is not enrolled in' do
    setup_access_control(user, create(:role, **base_permissions), non_window_project_viewable_collection)
    setup_access_control(user, create(:role, **base_permissions, **pdf_permissions), window_project_viewable_collection)

    get client_files_path(client_id: destination.id)

    expect(response).to have_http_status(:ok)
    expect(file_rows.size).to eq(0)
  end
end
