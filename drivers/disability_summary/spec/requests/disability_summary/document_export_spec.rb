###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Disability Summary document export', type: :request do
  let(:collection) { create(:collection) }
  let(:report_definition) { create(:touch_point_report, url: DisabilitySummary::DisabilitySummaryReport.url, name: 'Disability Summary') }
  let(:user) { create(:acl_user) }
  let(:query_string) { { filters: { start: 1.year.ago.to_date.to_s, end: Date.current.to_s } }.to_query }

  before do
    Rails.cache.clear
    collection.set_viewables({ reports: [report_definition.id] })
    setup_access_control(user, create(:role, name: 'assigned reports', can_view_assigned_reports: true, can_view_all_reports: true), collection)
  end

  it 'accepts a Disability Summary PDF export request' do
    sign_in(user)

    expect do
      post document_exports_path, params: { type: 'DisabilitySummary::DocumentExports::DisabilitySummaryExport', query_string: query_string }
    end.to change(GrdaWarehouse::DocumentExport, :count).by(1)
  end
end
