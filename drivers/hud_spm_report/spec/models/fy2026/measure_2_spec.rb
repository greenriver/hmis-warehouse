###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureTwo, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  describe 'returns within two years' do
    before do
      @es_project = create_project(project_type: 0)
      @client = create_client_with_warehouse_link

      # Permanent housing exit two years before the reporting period
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2020-12-01'.to_date,
        exit_date: '2021-05-15'.to_date,
        destination: 410,
        living_situation: 1,
      )

      # Return to homelessness within 181-365 day window
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-10'.to_date,
        exit_date: '2022-02-20'.to_date,
        living_situation: 1,
      )

      @report = setup_report([@es_project.id], ['Measure 2'])
      run_measure(@report, described_class)
      @table_name = '2a and 2b'
    end

    it 'categorizes exits and returns by window' do
      expect(@report.answer(question: @table_name, cell: 'B3').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'E3').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'I3').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'B7').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'E7').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'I7').summary).to eq(1)
    end
  end
end
