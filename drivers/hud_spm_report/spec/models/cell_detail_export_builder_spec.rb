# frozen_string_literal: true

require 'rails_helper'
require_relative './fy2026/shared_context'

RSpec.describe HudSpmReport::CellDetailExportBuilder, type: :model do
  include_context '2026 SPM test setup'

  describe '#call' do
    let(:user) { create(:user) }

    context 'Episode Universe (Measure 1)' do
      let(:project) { create_project(project_type: 0) }

      before do
        # Create a household to ensure we have real SpmEnrollment data
        @household_members = []
        build_household(
          projects: [project],
          entry_date: '2022-10-01'.to_date,
          exit_date: nil,
          members: 2,
          date_to_street_essh: '2022-10-01'.to_date,
          include_move_in: true,
          move_in_offset: 5,
        ) do |client, enrollment|
          @household_members << { client: client, enrollment: enrollment }
        end

        # Setup the report and create SPM enrollments
        @report = setup_report([project.id], ['Measure 1'])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      let(:builder) do
        described_class.new(
          user: user,
          report: @report,
          measure_id: 'Measure 1',
          cell_id: 'B2',
          table: '1a',
        )
      end

      it 'avoids N+1 queries when building the export package with real Episode data' do
        expect do
          builder.call
        end.to make_database_queries(count: 15)
      end
    end

    context 'Return Universe (Measure 2)' do
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
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureTwo)
      end

      let(:builder) do
        described_class.new(
          user: user,
          report: @report,
          measure_id: 'Measure 2',
          cell_id: 'E7',
          table: '2a and 2b',
        )
      end

      it 'avoids N+1 queries when building the export package with real Return data' do
        expect do
          builder.call
        end.to make_database_queries(count: 14)
      end
    end

    context 'SpmEnrollment Universe (Measure 3)' do
      before do
        @es_project = create_project(project_type: 0)

        create_enrollment(
          client: create_client_with_warehouse_link,
          project: @es_project,
          entry_date: '2023-01-10'.to_date,
          exit_date: '2023-03-01'.to_date,
        )

        @report = setup_report([@es_project.id], ['Measure 3'])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureThree)
      end

      let(:builder) do
        described_class.new(
          user: user,
          report: @report,
          measure_id: 'Measure 3',
          cell_id: 'C3',
          table: '3.2',
        )
      end

      it 'avoids N+1 queries when building the export package with real SpmEnrollment data' do
        expect do
          builder.call
        end.to make_database_queries(count: 13)
      end
    end
  end
end
