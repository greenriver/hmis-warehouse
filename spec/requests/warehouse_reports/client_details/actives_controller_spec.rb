###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../models/filters/criteria/shared_filter_criteria_context'

RSpec.describe WarehouseReports::ClientDetails::ActivesController, type: :request do
  include_context 'filter criteria setup'

  let(:filter_params) do
    {
      start: Date.new(2023, 1, 1),
      end: Date.new(2023, 12, 31),
      project_type_codes: ['es'],
      sub_population: 'clients',
      hoh_only: '0',
    }
  end

  let(:role) do
    create(
      :role,
      can_view_clients: true,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
    )
  end

  before do
    sign_in user
    # Ensure user has permission to view this report
    allow_any_instance_of(WarehouseReports::ClientDetails::ActivesController).
      to receive(:report_visible?).
      and_return(true)
  end

  describe 'GET #index' do
    context 'with valid filters' do
      it 'renders the report page successfully' do
        get warehouse_reports_client_details_actives_path, params: { filter: filter_params }

        expect(response).to have_http_status(:success)
        expect(response.body).to be_present
      end
    end

    context 'when project_type_codes are missing' do
      it 'shows validation error message' do
        invalid_params = filter_params.merge(project_type_codes: [])

        get warehouse_reports_client_details_actives_path, params: { filter: invalid_params }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('are required')
      end
    end
  end
end
