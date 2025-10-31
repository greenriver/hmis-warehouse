###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::WarehouseReports::GoalConfigsController, type: :controller do
  render_views
  let(:user) { create(:user) }
  let!(:default_goal) { create(:performance_measurement_goal) }

  before do
    sign_in user
    allow(controller).to receive(:report_visible?).and_return(true)
    allow(controller).to receive(:require_can_view_any_reports!).and_return(true)
  end

  describe 'PATCH #update' do
    it 'updates the default goal and redirects' do
      patch :update, params: {
        id: default_goal.id,
        goal: {
          always_run_for_coc: true,
          equity_analysis_visible: true,
          provider_comparisons_visible: true,
          approaching_threshold_percent: 7,
        },
      }

      default_goal.reload
      expect(default_goal.always_run_for_coc).to be(true)
      expect(default_goal.equity_analysis_visible).to be(true)
      expect(default_goal.provider_comparisons_visible).to be(true)
      expect(default_goal.approaching_threshold_percent).to eq(7)
      expect(response).to redirect_to(performance_measurement_warehouse_reports_goal_configs_path)
    end
  end

  describe 'POST #create' do
    it 'creates a new CoC-specific goal and redirects' do
      expect do
        post :create, params: {}
      end.to change(PerformanceMeasurement::Goal, :count).by(1)

      new_goal = PerformanceMeasurement::Goal.last
      expect(new_goal.coc_code).to eq('Un-Set')
      expect(response).to redirect_to(edit_performance_measurement_warehouse_reports_goal_config_path(new_goal))
    end
  end

  describe 'DELETE #destroy' do
    let!(:coc_goal) { create(:performance_measurement_goal, coc_code: 'COC-123') }

    it 'destroys the goal and redirects' do
      expect do
        delete :destroy, params: { id: coc_goal.id }
      end.to change(PerformanceMeasurement::Goal, :count).by(-1)
      expect(response).to redirect_to(performance_measurement_warehouse_reports_goal_configs_path)
    end
  end
end
