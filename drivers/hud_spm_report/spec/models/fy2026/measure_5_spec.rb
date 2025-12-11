###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureFive, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  describe 'first-time homelessness counts' do
    before do
      @es_project = create_project(project_type: 0)
      @ph_project = create_project(project_type: 3)

      build_current_entry(
        project: @es_project,
        entry_date: '2023-01-10'.to_date,
      )

      returning_es_client = build_current_entry(
        project: @es_project,
        entry_date: '2023-02-05'.to_date,
      )
      create_enrollment(
        client: returning_es_client,
        project: @es_project,
        entry_date: '2022-05-01'.to_date,
        exit_date: '2022-06-01'.to_date,
      )

      build_current_entry(
        project: @ph_project,
        entry_date: '2023-03-01'.to_date,
      )

      returning_ph_client = build_current_entry(
        project: @ph_project,
        entry_date: '2023-04-01'.to_date,
      )
      create_enrollment(
        client: returning_ph_client,
        project: @ph_project,
        entry_date: '2022-07-01'.to_date,
        exit_date: '2022-12-01'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id], ['Measure 5'])
      run_measure(@report, described_class)
    end

    it 'segments prior enrollments for measure 5.1 (ES/SH/TH)' do
      expect(@report.answer(question: '5.1', cell: 'C2').summary).to eq(2)
      expect(@report.answer(question: '5.1', cell: 'C3').summary).to eq(1)
      expect(@report.answer(question: '5.1', cell: 'C4').summary).to eq(1)
    end

    it 'segments prior enrollments for measure 5.2 (ES/SH/TH/PH)' do
      expect(@report.answer(question: '5.2', cell: 'C2').summary).to eq(4)
      expect(@report.answer(question: '5.2', cell: 'C3').summary).to eq(2)
      expect(@report.answer(question: '5.2', cell: 'C4').summary).to eq(2)
    end

    private

    def build_current_entry(project:, entry_date:)
      client = create_client_with_warehouse_link
      create_enrollment(
        client: client,
        project: project,
        entry_date: entry_date,
        exit_date: entry_date + 30.days,
      )
      client
    end
  end
end
