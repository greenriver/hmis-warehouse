###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureSeven, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  describe 'street outreach and housing placement outcomes' do
    before do
      @so_project = create_project(project_type: 4)
      @es_project = create_project(project_type: 0)
      @psh_project = create_project(project_type: 3)

      build_so_client(destination: 101) # temporary/Institutional
      build_so_client(destination: 410) # permanent

      build_es_client(destination: 410)

      build_psh_leaver(destination: 410)
      build_psh_stayer

      @report = setup_report([@so_project.id, @es_project.id, @psh_project.id], ['Measure 7'])
      run_measure(@report, described_class)
    end

    it 'summarizes Street Outreach exits' do
      expect(@report.answer(question: '7a.1', cell: 'C2').summary).to eq(2)
      expect(@report.answer(question: '7a.1', cell: 'C3').summary).to eq(1)
      expect(@report.answer(question: '7a.1', cell: 'C4').summary).to eq(1)
      expect(percent_for('7a.1', 'C5')).to eq(100.0)
    end

    it 'summarizes exits to permanent housing for sheltered projects' do
      expect(@report.answer(question: '7b.1', cell: 'C2').summary).to eq(1)
      expect(@report.answer(question: '7b.1', cell: 'C3').summary).to eq(1)
      expect(percent_for('7b.1', 'C4')).to eq(100.0)
    end

    it 'summarizes retention and exits for permanent housing projects' do
      expect(@report.answer(question: '7b.2', cell: 'C2').summary).to eq(2)
      expect(@report.answer(question: '7b.2', cell: 'C3').summary).to eq(2)
      expect(percent_for('7b.2', 'C4')).to eq(100.0)
    end

    private

    def value_for(table, cell)
      @report.answer(question: table, cell: cell).summary
    end

    def percent_for(table, cell)
      value_for(table, cell).to_f.round(2)
    end

    def build_so_client(destination:)
      client = create_client_with_warehouse_link
      create_enrollment(
        client: client,
        project: @so_project,
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-02-01'.to_date,
        destination: destination,
      )
    end

    def build_es_client(destination:)
      client = create_client_with_warehouse_link
      create_enrollment(
        client: client,
        project: @es_project,
        entry_date: '2023-01-15'.to_date,
        exit_date: '2023-03-01'.to_date,
        destination: destination,
      )
    end

    def build_psh_leaver(destination:)
      build_household(
        projects: [@psh_project],
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-06-01'.to_date,
        members: 1,
        include_move_in: true,
        move_in_offset: 9,
        destination: destination,
      )
    end

    def build_psh_stayer
      build_household(
        projects: [@psh_project],
        entry_date: '2023-02-01'.to_date,
        exit_date: nil,
        members: 1,
        include_move_in: true,
        move_in_offset: 30,
      )
    end
  end
end
