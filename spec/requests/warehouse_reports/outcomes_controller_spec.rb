###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::OutcomesController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:report_viewer) }

  outcomes_reports = {
    rrh: { url: 'warehouse_reports/rrh', report_class: WarehouseReport::Outcomes::RrhReport },
    psh: { url: 'warehouse_reports/psh', report_class: WarehouseReport::Outcomes::PshReport },
    shelter: { url: 'warehouse_reports/shelter', report_class: WarehouseReport::Outcomes::EsReport },
    th: { url: 'warehouse_reports/th', report_class: WarehouseReport::Outcomes::ThReport },
  }

  # WarehouseReportAuthorization#related_report builds its URL with
  # url_for(action: :index), which resolves to warehouse_reports/rrh for every
  # outcomes scope, so the user needs access to the RRH report definition too.
  let!(:report_definitions) do
    outcomes_reports.map do |name, config|
      create(:touch_point_report, url: config[:url], name: name.to_s)
    end
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: report_definitions.map(&:id) })
    setup_access_control(user, role, collection)
    sign_in user
  end

  outcomes_reports.each do |name, config|
    describe "#{name} report" do
      # The form offers the report class's own sub-population keys, which are not
      # registered in AvailableSubPopulations (#10129).
      config[:report_class].available_subpopulations.each_key do |sub_population|
        it "renders when filtered by the #{sub_population} sub-population" do
          get "/#{config[:url]}", params: { filter: { sub_population: sub_population } }

          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
