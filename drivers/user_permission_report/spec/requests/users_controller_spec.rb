###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Serves the "Full Permissions" detail modal for a single user, opened from the User
# Permission Report index (reports/index.haml:52). It renders that user's complete
# access control configuration -- every role, collection, and user group.
#
#
# The report definition must exist and be granted through the user's collection: that is
# what WarehouseReportAuthorization#report_visible? checks, and this controller overrides
# related_report because it has no :index action for the concern's default to derive.
RSpec.describe UserPermissionReport::WarehouseReports::UsersController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }

  # Seed the real report definitions rather than fabricating one: the url is what
  # WarehouseReportAuthorization matches on, and find_by! makes a rename of the seeded
  # definition fail here instead of silently passing against a stale hardcoded url.
  # rails_helper only seeds definitions for runs that include HUD report driver examples.
  before { GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions }

  let(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.
      find_by!(url: 'user_permission_report/warehouse_reports/reports')
  end

  # The user whose permissions the request is trying to read.
  let!(:subject_user) { create(:acl_user) }
  let!(:subject_access_control) do
    setup_access_control(subject_user, create(:role, can_view_clients: true), create(:collection))
  end

  # `grant_report: true` puts the report definition in the collection, which is what
  # report_visible? requires on top of the can_view_assigned_reports permission.
  def sign_in_with(role, grant_report: false)
    collection.set_viewables(reports: [report_definition.id]) if grant_report
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET /user_permission_report/warehouse_reports/users/:id' do
    it 'denies a user who has not been granted this report' do
      # Holding can_view_assigned_reports is not enough on its own -- the report itself
      # has to be assigned to one of the user's collections.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get user_permission_report_warehouse_reports_user_path(subject_user)

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'denies a user with no report permission at all' do
      sign_in_with(create(:role, can_view_clients: true), grant_report: true)

      get user_permission_report_warehouse_reports_user_path(subject_user)

      expect(response).to have_http_status(:redirect)
    end

    it 'allows a user granted the report, and renders the subject user\'s configuration' do
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get user_permission_report_warehouse_reports_user_path(subject_user)

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:user)).to eq(subject_user)
        expect(response.body).to include(subject_access_control.role.name)
      end
    end
  end
end
