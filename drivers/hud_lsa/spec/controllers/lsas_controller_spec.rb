###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudLsa::LsasController, type: :controller do
  let(:user) { create(:user) }

  before(:each) do
    sign_in user
  end

  describe '#report_class' do
    it 'uses the version chosen in the filter' do
      controller.params = ActionController::Parameters.new(filter: { report_version: 'fy2027' })

      expect(controller.report_class).to eq(HudLsa::Generators::Fy2027::Lsa)
    end

    it 'honors an earlier version chosen in the filter' do
      controller.params = ActionController::Parameters.new(filter: { report_version: 'fy2026' })

      expect(controller.report_class).to eq(HudLsa::Generators::Fy2026::Lsa)
    end

    it 'falls back to HudHelper.current_version when none is chosen' do
      controller.params = ActionController::Parameters.new({})
      expected = "HudLsa::Generators::Fy#{HudHelper.current_version}::Lsa".constantize

      expect(controller.report_class).to eq(expected)
    end
  end

  describe '#report_name' do
    it 'matches the version chosen in the filter' do
      controller.params = ActionController::Parameters.new(filter: { report_version: 'fy2027' })

      expect(controller.send(:report_name)).to eq('Longitudinal System Analysis - FY 2027')
    end
  end
end
