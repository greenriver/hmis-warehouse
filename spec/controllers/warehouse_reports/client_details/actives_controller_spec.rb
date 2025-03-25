# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../models/filters/criteria/shared_filter_criteria_context'

RSpec.describe WarehouseReports::ClientDetails::ActivesController, type: :controller do
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

  # Create test data for different scenarios
  let!(:client1) { create(:grda_warehouse_hud_client) }
  let!(:client2) { create(:grda_warehouse_hud_client) }
  let!(:client3) { create(:grda_warehouse_hud_client) }

  # Enrollment within date range with correct project type
  let!(:matching_enrollment) do
    create_enrollment_for_client(
      client1,
      date: filter_params[:start] + 5.days,
      last_date_in_program: filter_params[:end] - 5.days,
      project_type: 1,
    )
  end

  # Enrollment outside date range
  let!(:outside_date_range_enrollment) do
    create_enrollment_for_client(
      client2,
      date: filter_params[:start] - 30.days,
      last_date_in_program: filter_params[:start] - 1.day,
      project_type: 1,
    )
  end

  # Enrollment with wrong project type
  let!(:wrong_project_type_enrollment) do
    create_enrollment_for_client(
      client3,
      date: filter_params[:start] + 5.days,
      last_date_in_program: filter_params[:end] - 5.days,
      project_type: 2,
    )
  end

  let(:role) do
    create(:role, can_view_clients: true, can_view_all_reports: true, can_view_assigned_reports: true)
  end

  before do
    sign_in user
    allow(controller).to receive(:report_visible?).and_return(true)
    allow(GrdaWarehouse::WarehouseReports::DocumentExports::ActiveClientReportExport).to receive(:new).and_return(
      GrdaWarehouse::WarehouseReports::DocumentExports::ActiveClientReportExport.new,
    )

    [
      matching_enrollment,
      outside_date_range_enrollment,
      wrong_project_type_enrollment,
    ].each do |enrollment|
      create(
        :service_history_service,
        service_history_enrollment: enrollment,
        record_type: 200,
        date: '2023-12-15'.to_date,
        client_id: enrollment.client_id,
        project_type: enrollment.project_type,
      )
    end
  end

  describe 'GET #index' do
    context 'with date range and project type filters' do
      it 'filters enrollments by date range' do
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
        get :index, params: { filter: filter_params }

        report = assigns(:report)
        enrollment_ids = report.enrollment_scope.map(&:id)

        # Should include enrollments within date range
        expect(enrollment_ids).to include(matching_enrollment.id)

        # Should exclude enrollments outside date range
        expect(enrollment_ids).not_to include(outside_date_range_enrollment.id)
      end

      it 'filters enrollments by project type' do
        get :index, params: { filter: filter_params }

        report = assigns(:report)
        enrollment_ids = report.enrollment_scope.map(&:id)

        # Should include enrollments with matching project type
        expect(enrollment_ids).to include(matching_enrollment.id)

        # Should exclude enrollments with non-matching project type
        expect(enrollment_ids).not_to include(wrong_project_type_enrollment.id)
      end
    end
  end

  describe 'Filter validation' do
    it 'requires project_type_codes' do
      invalid_params = filter_params.merge(project_type_codes: [])

      get :index, params: { filter: invalid_params }

      expect(assigns(:filter).errors[:project_type_codes]).to include('are required')
    end
  end
end
