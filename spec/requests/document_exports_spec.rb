###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentExportsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:cohort) { create(:cohort) }
  let(:collection) { create(:collection, collection_type: 'Cohorts') }
  let(:export_type) { 'GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport' }

  before do
    collection.set_viewables({ cohorts: [cohort.id] })
    setup_access_control(user, create(:role, can_download_cohorts: true, can_view_cohorts: true), collection)
    sign_in user
  end

  it 'logs which export was requested' do
    post document_exports_path, params: { type: export_type, query_string: { id: cohort.id }.to_query }

    log = ActivityLog.where(user_id: user.id, action_name: 'create').last
    expect([log.item_model, log.item_id, log.title]).to eq([export_type, user.document_exports.last.id, export_type])
  end

  it 'logs which export was downloaded' do
    export = GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.create!(
      user: user,
      query_string: { id: cohort.id }.to_query,
      status: DocumentExportBehavior::COMPLETED_STATUS,
      filename: 'cohort.xlsx',
      mime_type: DocumentExportBehavior::EXCEL_MIME_TYPE,
      file_data: 'xlsx-bytes',
    )

    get download_document_export_path(export)

    log = ActivityLog.where(user_id: user.id, action_name: 'download').last
    expect([log.item_model, log.item_id, log.title]).to eq([export_type, export.id, export_type])
  end

  it 'rejects the abstract performance export type' do
    post document_exports_path, params: { type: 'GrdaWarehouse::DocumentExports::BasePerformanceExport', query_string: '' }

    expect(response).to have_http_status(:bad_request)
  end
end
