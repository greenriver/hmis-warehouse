###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicReports::WarehouseReports::PublicConfigs', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      report_group: 'Reports',
      url: 'public_reports/warehouse_reports/public_configs',
      name: 'Public Report Configuration',
      description: '',
    )
  end

  before do
    collection.set_viewables(reports: [report_definition.id])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  it 're-renders the form with the error and keeps the saved value when a color is unsafe' do
    PublicReports::Setting.first_or_create.update!(summary_color: '#123456')

    post public_reports_warehouse_reports_public_configs_path, params: { config: { summary_color: 'red;}' } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include('Summary color is not a valid CSS value')
    expect(PublicReports::Setting.first.summary_color).to eq('#123456')
  end
end
