###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoreDemographicsReport::WarehouseReports::DemographicSummaryController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_core_demographics_report_warehouse_reports_demographic_summary_index_path }
  end
end
