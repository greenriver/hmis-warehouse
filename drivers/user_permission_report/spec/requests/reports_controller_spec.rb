###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# This report lists every user in one table, so the account status the User Directory report gets
# from its two scopes has to be decided per row here instead, by User#inactive?. The `active` flag
# alone is not that test -- it carries admin deactivation and nothing else, so an account expired
# through disuse or past its expiration date read Active here while the admin Accounts page listed
# it as inactive.
#
# inactive? closes that gap for the three shapes below, not for every shape the Accounts page
# lists: an account with the flag set, an expired_at in the future, and a stale last_activity_at
# is in the User.inactive scope but not in inactive?, and still reads Active. See
# hmis-warehouse-o2s.
RSpec.describe UserPermissionReport::WarehouseReports::ReportsController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }

  # Seed the real report definitions rather than fabricating one: the url is what
  # WarehouseReportAuthorization matches on. rails_helper only seeds definitions for runs that
  # include HUD report driver examples.
  before { GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions }

  let(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.
      find_by!(url: 'user_permission_report/warehouse_reports/reports')
  end

  # The control every example asserts against, so a label is shown to discriminate rather than
  # merely appear: this user is active by every measure and has to keep reading Active.
  let!(:listed_user) { create(:acl_user) }

  # `grant_report: true` puts the report definition in the collection, which is what
  # report_visible? requires on top of the can_view_assigned_reports permission.
  def sign_in_with(role, grant_report: false)
    collection.set_viewables(reports: [report_definition.id]) if grant_report
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  def sign_in_with_report_access
    sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)
  end

  # Status sits in the first cell of the user's row, alongside their email. Match on the email and
  # read only that cell: the signed-in user is listed too, and role and collection names fill the
  # cells further right.
  def status_cell_for(subject_user)
    row = Nokogiri::HTML(response.body).css('tbody tr').
      detect { |tr| tr.text.include?(subject_user.email) }

    raise "no report row found for #{subject_user.email}" if row.nil?

    row.css('td').first.text.squish
  end

  describe 'GET /user_permission_report/warehouse_reports/reports' do
    it 'denies a user who has not been granted this report' do
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get user_permission_report_warehouse_reports_reports_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'labels an active user Active' do
      sign_in_with_report_access

      get user_permission_report_warehouse_reports_reports_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(User.inactive).not_to include(listed_user)
        expect(status_cell_for(listed_user)).to include('Active')
      end
    end

    it 'labels a deactivated user with the reason, not Active' do
      flag_off = create(:acl_user, active: false)
      sign_in_with_report_access

      get user_permission_report_warehouse_reports_reports_path

      aggregate_failures do
        expect(status_cell_for(listed_user)).to include('Active')
        expect(status_cell_for(flag_off)).to include('Account deactivated')
        expect(status_cell_for(flag_off)).not_to include('Active')
      end
    end

    # Under Devise the `active` flag is only one of the three things that make a user inactive, so
    # an account whose flag is still set but whose activity has aged out has to be labelled too.
    # The jwt arm's scopes read the flag alone and have no `expire_after`, hence the tag.
    it 'labels a user whose activity has aged out with the reason, not Active', :devise_only do
      aged_out = create(:acl_user, active: true, last_activity_at: (User.expire_after + 1.day).ago)
      sign_in_with_report_access

      get user_permission_report_warehouse_reports_reports_path

      aggregate_failures do
        # The Accounts page lists this user as inactive, which is the disagreement the report had.
        expect(User.inactive).to include(aged_out)
        expect(status_cell_for(listed_user)).to include('Active')
        expect(status_cell_for(aged_out)).to include('Account expired due to inactivity')
        expect(status_cell_for(aged_out)).not_to include('Active')
      end
    end

    # See the aged-out example for why this arm is tagged.
    it 'labels a user past their expiration date with the reason, not Active', :devise_only do
      expired = create(:acl_user, active: true, expired_at: 1.day.ago)
      sign_in_with_report_access

      get user_permission_report_warehouse_reports_reports_path

      aggregate_failures do
        expect(User.inactive).to include(expired)
        expect(status_cell_for(listed_user)).to include('Active')
        expect(status_cell_for(expired)).to include('Account expired on')
        expect(status_cell_for(expired)).not_to include('Active')
      end
    end

    # inactive? guards the partial rather than being a synonym for it: overall_status has a wider
    # idea of what blocks a login, and for an account it rules out for some other reason it returns
    # a single nil -- an empty cell. Keep the account labelled.
    it 'still labels a locked account Active rather than rendering nothing', :devise_only do
      locked = create(:acl_user)
      locked.lock_access!
      sign_in_with_report_access

      get user_permission_report_warehouse_reports_reports_path

      aggregate_failures do
        expect(User.inactive).not_to include(locked)
        expect(status_cell_for(locked)).to include('Active')
      end
    end
  end
end
