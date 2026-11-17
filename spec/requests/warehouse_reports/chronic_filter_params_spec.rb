###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The Chronic concern permits exactly the attributes declared on Filters::Chronic.
RSpec.describe 'WarehouseReports::ChronicController filter params', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:report_viewer, can_view_clients: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/chronic', name: 'Potentially Chronic Clients') }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def selected_min_age
    Nokogiri::HTML(response.body).css('select#filter_min_age option[selected]').map { |o| o['value'] }
  end

  it 'applies a permitted min_age to the filter form' do
    get warehouse_reports_chronic_index_path, params: { filter: { min_age: '24' } }

    expect(response).to have_http_status(:ok)
    expect(selected_min_age).to eq(['24'])
  end

  it 'uses the default min_age when none is submitted' do
    get warehouse_reports_chronic_index_path

    expect(response).to have_http_status(:ok)
    expect(selected_min_age).to eq(['0'])
  end

  it 'ignores an unpermitted filter key' do
    get warehouse_reports_chronic_index_path, params: { filter: { min_age: '18', not_an_attribute: 'x' } }

    expect(response).to have_http_status(:ok)
    expect(selected_min_age).to eq(['18'])
  end
end
