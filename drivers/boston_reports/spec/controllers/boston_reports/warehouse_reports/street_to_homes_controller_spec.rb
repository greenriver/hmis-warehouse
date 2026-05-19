# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonReports::WarehouseReports::StreetToHomesController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_boston_reports_warehouse_reports_street_to_homes_path }
  end
end
