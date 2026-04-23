# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DestinationReport::WarehouseReports::ReportsController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_destination_report_warehouse_reports_reports_path }
  end
end
