###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::WarehouseReports::StaticSpmsController, type: :controller do
  render_views
  let(:user) { create(:user) }
  let(:goal) { create(:performance_measurement_goal) }

  before do
    sign_in user
    allow(controller).to receive(:report_visible?).and_return(true)
    allow(controller).to receive(:require_can_view_any_reports!).and_return(true)
  end

  describe 'POST #create' do
    it 'creates a new static spm and redirects' do
      spm_params = {
        report_start: Date.new(2024, 1, 1),
        report_end: Date.new(2024, 12, 31),
      }

      PerformanceMeasurement::StaticSpm::KNOWN_SPM_METHODS.each do |_, _, method|
        spm_params[method] = rand(1..100)
      end

      expect do
        post :create, params: { goal_config_id: goal.id, spm: spm_params }
      end.to change(PerformanceMeasurement::StaticSpm, :count).by(1)

      expect(response).to redirect_to(edit_performance_measurement_warehouse_reports_goal_config_path(goal))
      new_spm = PerformanceMeasurement::StaticSpm.last
      expect(new_spm.report_start).to eq(Date.new(2024, 1, 1))
      # check one of the data values to make sure data is being saved
      expect(new_spm.table_1a_cell_d2).to be_a(Float)
    end
  end

  describe 'PATCH #update' do
    let!(:spm) { create(:performance_measurement_static_spm, :with_data, goal: goal) }

    it 'updates the static spm and redirects' do
      new_start_date = Date.new(2023, 1, 1)
      patch :update, params: {
        goal_config_id: goal.id,
        id: spm.id,
        spm: { report_start: new_start_date },
      }

      spm.reload
      expect(spm.report_start).to eq(new_start_date)
      expect(response).to redirect_to(edit_performance_measurement_warehouse_reports_goal_config_path(goal))
    end
  end

  describe 'DELETE #destroy' do
    let!(:spm) { create(:performance_measurement_static_spm, goal: goal) }

    it 'destroys the static spm and redirects' do
      expect do
        delete :destroy, params: { goal_config_id: goal.id, id: spm.id }
      end.to change(PerformanceMeasurement::StaticSpm, :count).by(-1)

      expect(response).to redirect_to(edit_performance_measurement_warehouse_reports_goal_config_path(goal))
    end
  end
end
