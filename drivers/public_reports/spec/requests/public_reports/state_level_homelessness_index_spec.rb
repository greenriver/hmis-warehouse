require 'rails_helper'

RSpec.describe 'State-level homelessness report index', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }

  before do
    ['state_level_homelessness', 'state_dashboard'].each do |slug|
      GrdaWarehouse::WarehouseReports::ReportDefinition.create!(report_group: 'Public', url: "public_reports/warehouse_reports/#{slug}", name: slug, description: '')
    end
    collection.set_viewables(reports: GrdaWarehouse::WarehouseReports::ReportDefinition.pluck(:id))
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  it 'points users at the State Dashboard' do
    get public_reports_warehouse_reports_state_level_homelessness_index_path

    link = Nokogiri::HTML(response.body).at_css('.alert-warning a')
    expect(link&.[]('href')).to eq(public_reports_warehouse_reports_state_dashboard_index_path)
  end
end
