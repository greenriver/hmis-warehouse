###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# User Directory Report: name, email, phone and agency for every user in the directory,
# in HTML and as an xlsx download, for both the warehouse and (where configured) CAS.
#
RSpec.describe UserDirectoryReport::WarehouseReports::UsersController, type: :request do
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
      find_by!(url: 'user_directory_report/warehouse_reports/users/warehouse')
  end

  # A user who should appear in the directory once access is allowed, and whose absence
  # from an unauthorized response is what we assert on.
  let!(:listed_user) { create(:acl_user, first_name: 'Directory', last_name: 'Listing') }

  def sign_in_with(role, grant_report: false)
    collection.set_viewables(reports: [report_definition.id]) if grant_report
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET /user_directory_report/warehouse_reports/users/warehouse' do
    it 'denies a user who has not been granted this report' do
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'denies a user with no report permission at all' do
      sign_in_with(create(:role, can_view_clients: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      expect(response).to have_http_status(:redirect)
    end

    it 'denies the xlsx export for a user who has not been granted this report' do
      # The export is a separate format on the same action; a gate that only covered the
      # html path would still leak the whole directory as a spreadsheet.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get warehouse_user_directory_report_warehouse_reports_users_path(format: :xlsx)

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        # The action sets an attachment disposition when it builds the spreadsheet, so
        # its absence distinguishes "refused" from "redirected after generating a file".
        expect(response.headers['Content-Disposition']).to be_blank
      end
    end

    it 'allows a user granted the report, and lists directory users' do
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:users)).to include(listed_user)
      end
    end

    it 'omits inactive users' do
      # `active` is only one of the three things that make a user inactive, so an account
      # whose flag is still set but whose activity has aged out has to be omitted too.
      aged_out = create(:acl_user, active: true, last_activity_at: (Devise.expire_after + 1.day).ago)
      flag_off = create(:acl_user, active: false)
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(assigns(:users)).to include(listed_user)
        expect(assigns(:users)).not_to include(aged_out, flag_off)
      end
    end
  end

  describe 'GET /user_directory_report/warehouse_reports/users/inactive' do
    it 'denies a user who has not been granted this report' do
      # The inactive listing shares the warehouse action's report definition, so the
      # override of related_report has to cover it too.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get inactive_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'lists the inactive directory users, and only those' do
      aged_out = create(:acl_user, active: true, last_activity_at: (Devise.expire_after + 1.day).ago)
      flag_off = create(:acl_user, active: false)
      excluded = create(:acl_user, active: false, exclude_from_directory: true)
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get inactive_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:users)).to include(aged_out, flag_off)
        expect(assigns(:users)).not_to include(listed_user, excluded)
      end
    end
  end

  describe 'GET /user_directory_report/warehouse_reports/users/cas' do
    it 'denies a user who has not been granted this report' do
      # The cas action shares the warehouse action's report definition, so the override
      # of related_report has to cover it too.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get cas_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    # No allow-path example for #cas: the action raises before it renders whenever CAS is
    # not configured, which includes the test environment. `cas_available?` is false, so
    # @users is set to a plain Array and handed to pagy, which needs a relation --
    # NoMethodError: undefined method 'offset' for an instance of Array. That is a
    # pre-existing bug in the action (it predates the authorization gate added here) and
    # is tracked separately; the deny example above is what pins the gate itself.
  end
end
