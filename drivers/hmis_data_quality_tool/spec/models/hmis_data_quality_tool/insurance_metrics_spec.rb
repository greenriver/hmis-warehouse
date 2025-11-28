###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  include_context 'DQ Tool test setup'

  describe 'Insurance Metrics' do
    describe 'Insurance From Any Source at Entry' do
      context 'with valid insurance data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: '2022-11-01'.to_date,
            insurance_from_any_source: 1, # Yes
            DataCollectionStage: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid insurance data' do
          expect_result(key: :insurance_from_any_source_at_entry, invalid_count: 0)
        end
      end

      context 'with missing insurance data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: '2022-11-01'.to_date,
            insurance_from_any_source: 99, # Data not collected
            DataCollectionStage: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing insurance data' do
          expect_result(key: :insurance_from_any_source_at_entry, invalid_count: 1)
        end
      end
    end

    describe 'Insurance From Any Source at Annual Assessment' do
      context 'with valid insurance data' do
        before do
          @project = create_project(project_type: 3) # PSH
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          entry_date = report_end - 400.days
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: entry_date,
            exit_date: nil,
            relationship_to_ho_h: 1,
          )
          anniversary_date = entry_date + 1.year
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: anniversary_date,
            insurance_from_any_source: 1, # Yes
            DataCollectionStage: 5, # Annual assessment
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid insurance data' do
          expect_result(key: :insurance_from_any_source_at_annual, invalid_count: 0)
        end
      end

      context 'with missing insurance data' do
        before do
          @project = create_project(project_type: 3) # PSH
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          entry_date = report_end - 400.days
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: entry_date,
            exit_date: nil,
            relationship_to_ho_h: 1,
          )
          anniversary_date = entry_date + 1.year
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: anniversary_date,
            insurance_from_any_source: 99, # Data not collected
            DataCollectionStage: 5, # Annual assessment
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing insurance data' do
          expect_result(key: :insurance_from_any_source_at_annual, invalid_count: 1)
        end
      end
    end

    describe 'Insurance From Any Source at Exit' do
      context 'with valid insurance data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          exit_date = '2023-01-15'.to_date
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: exit_date,
          )
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: exit_date,
            insurance_from_any_source: 1, # Yes
            DataCollectionStage: 3, # Exit
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid insurance data' do
          expect_result(key: :insurance_from_any_source_at_exit, invalid_count: 0)
        end
      end

      context 'with missing insurance data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          exit_date = '2023-01-15'.to_date
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: exit_date,
          )
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: exit_date,
            insurance_from_any_source: 99, # Data not collected
            DataCollectionStage: 3, # Exit
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing insurance data' do
          expect_result(key: :insurance_from_any_source_at_exit, invalid_count: 1)
        end
      end
    end

    describe 'Insurance Matches Expected Value' do
      describe 'at Entry' do
        context 'with insurance yes but no insurance sources' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
            )
            create(
              :hud_income_benefit,
              enrollment: @enrollment,
              data_source: data_source,
              information_date: '2022-11-01'.to_date,
              insurance_from_any_source: 1, # Yes
              DataCollectionStage: 1, # Entry
              # No insurance sources set (mismatch: should have at least one insurance source if insurance_from_any_source is yes)
            )
            @report = setup_report([@project.id])
          end

          it 'flags insurance mismatch' do
            expect_result(key: :insurance_as_expected_at_entry, invalid_count: 1)
          end
        end

        context 'with insurance no but insurance sources present' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
            )
            create(
              :hud_income_benefit,
              enrollment: @enrollment,
              data_source: data_source,
              information_date: '2022-11-01'.to_date,
              insurance_from_any_source: 0, # No
              DataCollectionStage: 1, # Entry
              Medicaid: 1, # Yes - but insurance_from_any_source is no (mismatch)
            )
            @report = setup_report([@project.id])
          end

          it 'flags insurance mismatch' do
            expect_result(key: :insurance_as_expected_at_entry, invalid_count: 1)
          end
        end
      end

      describe 'at Annual Assessment' do
        context 'with insurance yes but no insurance sources' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            entry_date = report_end - 400.days
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
            )
            anniversary_date = entry_date + 1.year
            create(
              :hud_income_benefit,
              enrollment: @enrollment,
              data_source: data_source,
              information_date: anniversary_date,
              insurance_from_any_source: 1, # Yes
              DataCollectionStage: 5, # Annual assessment
              # No insurance sources set (mismatch: should have at least one insurance source if insurance_from_any_source is yes)
            )
            @report = setup_report([@project.id])
          end

          it 'flags insurance mismatch' do
            expect_result(key: :insurance_as_expected_at_annual, invalid_count: 1)
          end
        end

        context 'with insurance no but insurance sources present' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            entry_date = report_end - 400.days
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
            )
            anniversary_date = entry_date + 1.year
            create(
              :hud_income_benefit,
              enrollment: @enrollment,
              data_source: data_source,
              information_date: anniversary_date,
              insurance_from_any_source: 0, # No
              DataCollectionStage: 5, # Annual assessment
              Medicaid: 1, # Yes - but insurance_from_any_source is no (mismatch)
            )
            @report = setup_report([@project.id])
          end

          it 'flags insurance mismatch' do
            expect_result(key: :insurance_as_expected_at_annual, invalid_count: 1)
          end
        end
      end

      describe 'at Exit' do
        context 'with insurance yes but no insurance sources' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link
            exit_date = '2023-01-15'.to_date
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: exit_date,
            )
            create(
              :hud_income_benefit,
              enrollment: @enrollment,
              data_source: data_source,
              information_date: exit_date,
              insurance_from_any_source: 1, # Yes
              DataCollectionStage: 3, # Exit
              # No insurance sources set (mismatch: should have at least one insurance source if insurance_from_any_source is yes)
            )
            @report = setup_report([@project.id])
          end

          it 'flags insurance mismatch' do
            expect_result(key: :insurance_as_expected_at_exit, invalid_count: 1)
          end
        end

        context 'with insurance no but insurance sources present' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link
            exit_date = '2023-01-15'.to_date
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: exit_date,
            )
            create(
              :hud_income_benefit,
              enrollment: @enrollment,
              data_source: data_source,
              information_date: exit_date,
              insurance_from_any_source: 0, # No
              DataCollectionStage: 3, # Exit
              Medicaid: 1, # Yes - but insurance_from_any_source is no (mismatch)
            )
            @report = setup_report([@project.id])
          end

          it 'flags insurance mismatch' do
            expect_result(key: :insurance_as_expected_at_exit, invalid_count: 1)
          end
        end
      end
    end
  end
end
