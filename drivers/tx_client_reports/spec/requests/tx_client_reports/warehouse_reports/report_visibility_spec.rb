###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TxClientReports::WarehouseReports::ResearchExports visibility', type: :request do
  let(:report_class) { TxClientReports::ResearchExport }
  let(:report_definition_url) { 'tx_client_reports/warehouse_reports/research_exports' }
  let(:report_path) { ->(report) { tx_client_reports_warehouse_reports_research_export_path(report) } }

  it_behaves_like 'report member actions limited to visible reports', destroy: false
end
