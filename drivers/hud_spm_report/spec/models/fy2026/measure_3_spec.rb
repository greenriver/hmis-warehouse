###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureThree, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  describe 'annual counts (3.2)' do
    before do
      @es_project = create_project(project_type: 0)
      @nbn_project = create_project(project_type: 1)
      @sh_project = create_project(project_type: 8)
      @th_project = create_project(project_type: 2)

      @es_enrollment = create_enrollment(
        client: create_client_with_warehouse_link,
        project: @es_project,
        entry_date: '2023-01-10'.to_date,
        exit_date: '2023-03-01'.to_date,
      )

      @nbn_enrollment = create_enrollment(
        client: create_client_with_warehouse_link,
        project: @nbn_project,
        entry_date: '2023-02-01'.to_date,
        exit_date: '2023-02-20'.to_date,
      )
      add_bed_nights(
        enrollment: @nbn_enrollment,
        start_date: @nbn_enrollment.entry_date,
        end_date: @nbn_enrollment.real_exit_date,
      )

      @sh_enrollment = create_enrollment(
        client: create_client_with_warehouse_link,
        project: @sh_project,
        entry_date: '2023-04-01'.to_date,
        exit_date: '2023-06-01'.to_date,
      )

      @th_enrollment = create_enrollment(
        client: create_client_with_warehouse_link,
        project: @th_project,
        entry_date: '2023-05-15'.to_date,
        exit_date: '2023-09-15'.to_date,
      )

      @report = setup_report(
        [@es_project.id, @nbn_project.id, @sh_project.id, @th_project.id],
        ['Measure 3'],
      )
      run_measure(@report, described_class)
    end

    it 'counts total sheltered persons across project types' do
      expect(@report.answer(question: '3.2', cell: 'C2').summary).to eq(4)
      expect(@report.universe(:m3_2_c2).members.count).to eq(4)
    end

    it 'breaks out the emergency shelter population' do
      expect(@report.answer(question: '3.2', cell: 'C3').summary).to eq(2)
      expect(@report.universe(:m3_2_c3).members.count).to eq(2)
    end

    it 'isolates safe haven and transitional housing counts' do
      expect(@report.answer(question: '3.2', cell: 'C4').summary).to eq(1)
      expect(@report.answer(question: '3.2', cell: 'C5').summary).to eq(1)
    end
  end
end
