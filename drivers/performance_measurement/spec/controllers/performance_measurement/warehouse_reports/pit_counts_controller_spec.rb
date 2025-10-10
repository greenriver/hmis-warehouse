###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::WarehouseReports::PitCountsController, type: :controller do
  render_views
  let(:user) { create(:user) }
  let(:goal) { create(:performance_measurement_goal) }

  before do
    sign_in user
    allow(controller).to receive(:report_visible?).and_return(true)
    allow(controller).to receive(:require_can_view_any_reports!).and_return(true)
  end

  describe 'POST #create' do
    it 'creates a new PIT count and redirects' do
      pit_count_params = {
        pit_date: Time.zone.today,
        unsheltered: 50,
        sheltered: 100,
      }

      expect do
        post :create, params: { goal_config_id: goal.id, pit_count: pit_count_params }
      end.to change(PerformanceMeasurement::PitCount, :count).by(1)

      expect(response).to redirect_to(edit_performance_measurement_warehouse_reports_goal_config_path(goal))
      new_pit_count = PerformanceMeasurement::PitCount.last
      expect(new_pit_count.pit_date).to eq(Time.zone.today)
      expect(new_pit_count.unsheltered).to eq(50)
      expect(new_pit_count.sheltered).to eq(100)
    end
  end

  describe 'DELETE #destroy' do
    let!(:pit_count) { create(:performance_measurement_pit_count, goal: goal) }

    it 'destroys the PIT count and redirects' do
      expect do
        delete :destroy, params: { goal_config_id: goal.id, id: pit_count.id }
      end.to change(PerformanceMeasurement::PitCount, :count).by(-1)

      expect(response).to redirect_to(edit_performance_measurement_warehouse_reports_goal_config_path(goal))
    end
  end
end
