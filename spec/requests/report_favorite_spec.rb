require 'rails_helper'

RSpec.describe 'Report Favorite', type: :request do
  let(:agency) { create :agency }
  let(:role) { create :report_viewer }
  let(:user) { create :user, roles: [role], agency: agency }
  let!(:report) { create :core_demographics_report }

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    AccessGroup.maintain_system_groups
    user.add_viewable(report)
    sign_in user
  end

  it 'can load the reports page' do
    get warehouse_reports_path
    expect(response.body).to include 'Core Demographics'
  end
  it 'Trigger favorite/unfavorite' do
    put favorite_api_report_path(report)
    expect(Favorite.count).to eq 1
    expect(report.reload.deleted_at).to eq(nil)
    put unfavorite_api_report_path(report)
    expect(Favorite.count).to eq 0
    expect(report.reload.deleted_at).to eq(nil)
    expect(GrdaWarehouse::WarehouseReports::ReportDefinition.count).to be > 0
    expect(GrdaWarehouse::WarehouseReports::ReportDefinition.only_deleted.count).to eq(0)
  end
end
