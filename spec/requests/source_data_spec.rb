###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Source data ExportID note', type: :request do
  let(:note) { 'ExportID is from the import that last wrote this record' }
  let(:data_source) { create(:authoritative_data_source) }
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_upload_hud_zips: true, can_edit_data_sources: true, can_view_projects: true, can_view_clients: true) }
  let(:user_group) { create(:user_group) }
  let(:collection) { create(:collection) }
  let(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }
  let(:client) { create(:grda_warehouse_hud_client, data_source: data_source) }
  let(:project) { create(:grda_warehouse_hud_project, data_source: data_source) }
  let!(:enrollment) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source: data_source,
      client: client,
      project: project,
      ExportID: 'old',
    )
  end

  def create_staging_enrollment(export_id:)
    HmisCsvTwentyTwentySix::Importer::Enrollment.create!(
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: enrollment.PersonalID,
      data_source_id: data_source.id,
      ExportID: export_id,
      importer_log_id: importer_log.id,
      pre_processed_at: importer_log.created_at,
      source_id: enrollment.id,
      source_type: enrollment.class.name,
    )
  end

  before do
    user_group.add(user)
    create(:access_control, role: role, collection: collection, user_group: user_group)
    collection.set_viewables({ data_sources: [data_source.id] })
    sign_in user
  end

  it 'explains the ExportID when the newest staging row has a different ExportID' do
    create_staging_enrollment(export_id: 'new')

    get source_datum_path(id: enrollment.id, type: 'Enrollment')

    expect(response).to have_http_status(:success)
    expect(response.body).to include(note)
  end

  it 'omits the explanation when the staging ExportID matches the warehouse row' do
    create_staging_enrollment(export_id: 'old')

    get source_datum_path(id: enrollment.id, type: 'Enrollment')

    expect(response).to have_http_status(:success)
    expect(assigns(:imported).ExportID).to eq('old')
    expect(response.body).not_to include(note)
  end
end
