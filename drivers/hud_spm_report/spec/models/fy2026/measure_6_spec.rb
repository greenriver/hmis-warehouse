###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureSix, type: :model, exclude_fixpoints: true do
  include_context 'SPM test setup'

  describe 'table scaffolding' do
    before do
      project = create_project(project_type: 2)
      @report = setup_report([project.id], ['Measure 6'])
      run_measure(@report, described_class)
    end

    it 'builds the return table without data' do
      %w[B2 C2 G7 J7].each do |cell|
        expect(@report.answer(question: '6a.1 and 6b.1', cell: cell).summary).to eq(0)
      end
    end

    it 'builds the category 3 placement tables' do
      expect(@report.answer(question: '6c.1', cell: 'C2').summary).to eq(0)
      expect(@report.answer(question: '6c.2', cell: 'C2').summary).to eq(0)
    end
  end
end
