###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalysisTool::WarehouseReports::AnalysisToolController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_analysis_tool_warehouse_reports_analysis_tool_index_path }
  end
end
