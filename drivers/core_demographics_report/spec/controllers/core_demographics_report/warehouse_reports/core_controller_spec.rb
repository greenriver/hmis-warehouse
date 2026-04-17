# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoreDemographicsReport::WarehouseReports::CoreController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_core_demographics_report_warehouse_reports_core_index_path }
  end
end
