###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Row-level youth data is separately scoped: every source the report reads goes through
# GrdaWarehouse::YouthIntake::Entry.visible_by?(filter.user) and its siblings (see
# GrdaWarehouse::WarehouseReports::Youth::InactiveIntake#intake_source and friends), which
# return `none` for a user with no youth intake permission. So the gate below controls
# access to the report, not to the youth data itself -- both layers matter.
RSpec.describe WarehouseReports::InactiveYouthIntakesController, type: :request do
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
      find_by!(url: 'warehouse_reports/inactive_youth_intakes')
  end

  # `grant_report: true` puts the report definition in the user's collection, which is
  # what WarehouseReportAuthorization#report_visible? requires on top of the permission.
  def sign_in_with(role, grant_report: false)
    collection.set_viewables(reports: [report_definition.id]) if grant_report
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET /warehouse_reports/inactive_youth_intakes' do
    it 'denies a user who has not been granted this report' do
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get warehouse_reports_inactive_youth_intakes_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'denies a user with no report permission at all' do
      sign_in_with(create(:role, can_view_clients: true), grant_report: true)

      get warehouse_reports_inactive_youth_intakes_path

      expect(response).to have_http_status(:redirect)
    end

    it 'allows a user granted the report' do
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get warehouse_reports_inactive_youth_intakes_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:report)).to be_present
      end
    end

    it 'defaults the filter range when none is submitted' do
      # set_filter computes its default range from the clock: the beginning of the month
      # three months earlier, through the previous day. The request below runs with time
      # frozen, so those resolve to the fixed dates asserted there.
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      travel_to Time.zone.local(2025, 6, 15, 12, 0, 0) do
        get warehouse_reports_inactive_youth_intakes_path

        aggregate_failures do
          expect(assigns(:filter).start).to eq(Date.new(2025, 3, 1))
          expect(assigns(:filter).end).to eq(Date.new(2025, 6, 14))
        end
      end
    end
  end
end
