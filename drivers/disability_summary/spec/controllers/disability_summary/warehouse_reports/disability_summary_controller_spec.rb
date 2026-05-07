# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisabilitySummary::WarehouseReports::DisabilitySummaryController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_disability_summary_warehouse_reports_disability_summary_index_path }
  end
end
