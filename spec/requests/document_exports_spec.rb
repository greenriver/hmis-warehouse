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

  def completed_export_for(cohort_id)
    GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.create!(
      user: user,
      query_string: { id: cohort_id }.to_query,
      status: DocumentExportBehavior::COMPLETED_STATUS,
      filename: 'cohort.xlsx',
      mime_type: DocumentExportBehavior::EXCEL_MIME_TYPE,
      file_data: 'xlsx-bytes',
    )
  end

  it 'logs which export was downloaded' do
    export = completed_export_for(cohort.id)

    get download_document_export_path(export)

    log = ActivityLog.where(user_id: user.id, action_name: 'download').last
    expect([log.item_model, log.item_id, log.title]).to eq([export_type, export.id, export_type])
  end

  it 'refuses to download a completed export for a cohort the user cannot view' do
    export = completed_export_for(create(:cohort).id)

    get download_document_export_path(export)

    expect(response).to redirect_to(user.my_root_path)
    expect(response.body).not_to include('xlsx-bytes')
    expect(ActivityLog.where(user_id: user.id, action_name: 'download').count).to eq(0)
  end

  it 'rejects the abstract performance export type' do
    post document_exports_path, params: { type: 'GrdaWarehouse::DocumentExports::BasePerformanceExport', query_string: '' }

    expect(response).to have_http_status(:bad_request)
  end

  describe 'cohort export authorization is per cohort' do
    let(:other_cohort) { create(:cohort) }

    def grant(role_user, permissions, record)
      collection = create(:collection, collection_type: 'Cohorts')
      collection.set_viewables({ cohorts: [record.id] })
      setup_access_control(role_user, create(:role, **permissions.index_with { true }), collection)
    end

    def create_export_for(cohort_id)
      post document_exports_path, params: { type: export_type, query_string: { id: cohort_id }.to_query }
    end

    it 'refuses a cohort the user can only view, even when they can download another' do
      grant(user, [:can_view_cohorts], other_cohort)

      create_export_for(other_cohort.id)

      expect(response).to redirect_to(user.my_root_path)
      expect(user.document_exports.where(type: export_type).count).to eq(0)
    end

    it 'allows the cohort the download permission was granted on' do
      create_export_for(cohort.id)

      expect(response).to have_http_status(:ok)
      expect(user.document_exports.count).to eq(1)
    end

    it 'refuses a manager-only user' do
      manager = create(:acl_user)
      grant(manager, [:can_configure_cohorts, :can_download_cohorts], other_cohort)
      sign_in manager

      create_export_for(other_cohort.id)

      expect(response).to redirect_to(manager.my_root_path)
      expect(manager.document_exports.count).to eq(0)
    end

    describe 'downloading an existing export' do
      def expect_download_refused(export_user, export)
        get download_document_export_path(export)

        expect(response).to be_redirect
        expect(response.location).to end_with(export_user.my_root_path)
        expect(response.body).not_to include('xlsx-bytes')
      end

      def completed_export(export_user, cohort_id)
        GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.create!(
          user: export_user,
          query_string: { id: cohort_id }.to_query,
          status: DocumentExportBehavior::COMPLETED_STATUS,
          filename: 'cohort.xlsx',
          mime_type: DocumentExportBehavior::EXCEL_MIME_TYPE,
          file_data: 'xlsx-bytes',
        )
      end

      it 'is refused for a cohort the user can only view' do
        grant(user, [:can_view_cohorts], other_cohort)

        expect_download_refused(user, completed_export(user, other_cohort.id))
        expect(ActivityLog.where(user_id: user.id, action_name: 'download').count).to eq(0)
      end

      it 'is allowed for a cohort where download was granted' do
        grant(user, [:can_view_cohorts], other_cohort)

        export = completed_export(user, cohort.id)

        expect { get download_document_export_path(export) }.
          to change { ActivityLog.where(user_id: user.id, action_name: 'download').count }.from(0).to(1)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('xlsx-bytes')
        log = ActivityLog.where(user_id: user.id, action_name: 'download').last
        expect([log.item_model, log.item_id, log.title]).to eq([export.class.name, export.id, export.type])
      end

      it 'is refused for a manager-only user' do
        manager = create(:acl_user)
        grant(manager, [:can_configure_cohorts, :can_download_cohorts], other_cohort)
        sign_in manager

        expect_download_refused(manager, completed_export(manager, other_cohort.id))
      end
    end

    it 'refuses a legacy user whose download permission does not reach the cohort' do
      legacy = create(:user)
      access_group = create(:access_group)
      create(:role, can_view_cohorts: true, can_download_cohorts: true).add(legacy)
      access_group.add(legacy)
      access_group.add_viewable(cohort)
      sign_in legacy

      create_export_for(other_cohort.id)
      expect(response).to redirect_to(legacy.my_root_path)

      create_export_for(cohort.id)
      expect(response).to have_http_status(:ok)
    end
  end
end
