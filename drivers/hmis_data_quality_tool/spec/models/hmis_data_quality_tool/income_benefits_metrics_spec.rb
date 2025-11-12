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

  describe 'Income and Benefits Metrics' do
    describe 'Income From Any Source at Entry' do
      context 'with valid income data for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
            income_from_any_source: 1, # Yes
            DataCollectionStage: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid income data' do
          expect_result(title: 'Income From Any Source at Entry', invalid_count: 0)
        end
      end

      context 'with missing income data for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
            income_from_any_source: 99, # Data not collected
            DataCollectionStage: 1, # Entry
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing income data' do
          expect_result(title: 'Income From Any Source at Entry', invalid_count: 1)
        end
      end
    end

    describe 'Income From Any Source at Annual Assessment' do
      context 'with valid income data for adult' do
        before do
          @project = create_project(project_type: 3) # PSH
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          # Create enrollment that started more than a year ago
          entry_date = report_end - 400.days
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: entry_date,
            exit_date: nil,
            relationship_to_ho_h: 1,
          )
          # Calculate anniversary date (entry_date + 1 year)
          # Annual assessment must be within 30 days of anniversary date
          anniversary_date = entry_date + 1.year
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: anniversary_date, # On anniversary date (within 30-day window)
            income_from_any_source: 1, # Yes
            DataCollectionStage: 5, # Annual assessment
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid income data' do
          expect_result(title: 'Income From Any Source at Annual Assessment', invalid_count: 0)
        end
      end

      context 'with missing income data for adult' do
        before do
          @project = create_project(project_type: 3) # PSH
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          # Create enrollment that started more than a year ago
          entry_date = report_end - 400.days
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: entry_date,
            exit_date: nil,
            relationship_to_ho_h: 1,
          )
          # Calculate anniversary date (entry_date + 1 year)
          anniversary_date = entry_date + 1.year
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            information_date: anniversary_date,
            income_from_any_source: 99, # Data not collected
            DataCollectionStage: 5, # Annual assessment
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing income data' do
          expect_result(title: 'Income From Any Source at Annual Assessment', invalid_count: 1)
        end
      end
    end

    describe 'Income From Any Source at Exit' do
      context 'with valid income data for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
            income_from_any_source: 1, # Yes
            DataCollectionStage: 3, # Exit
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid income data' do
          expect_result(title: 'Income From Any Source at Exit', invalid_count: 0)
        end
      end

      context 'with missing income data for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
            income_from_any_source: 99, # Data not collected
            DataCollectionStage: 3, # Exit
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing income data' do
          expect_result(title: 'Income From Any Source at Exit', invalid_count: 1)
        end
      end
    end

    describe 'Cash Income Matches Expected Value' do
      describe 'at Entry' do
        context 'with income yes but no cash sources' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 1, # Yes
              total_monthly_income: 0,
              DataCollectionStage: 1, # Entry
              Earned: 1, # Yes - but amount is 0 (mismatch: should have positive amount if source is yes)
              EarnedAmount: 0,
            )
            @report = setup_report([@project.id])
          end

          it 'flags cash income mismatch' do
            expect_result(title: 'Cash Income Matches Expected Value at Entry', invalid_count: 1)
          end
        end

        context 'with income no but cash sources present' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 0, # No
              total_monthly_income: 500, # But has income amount
              DataCollectionStage: 1, # Entry
              Earned: 0, # No - but amount is positive (mismatch: should not have amount if source is no)
              EarnedAmount: 500,
            )
            @report = setup_report([@project.id])
          end

          it 'flags cash income mismatch' do
            expect_result(title: 'Cash Income Matches Expected Value at Entry', invalid_count: 1)
          end
        end
      end

      describe 'at Annual Assessment' do
        context 'with income yes but no cash sources' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 1, # Yes
              total_monthly_income: 0,
              DataCollectionStage: 5, # Annual assessment
              Earned: 1, # Yes - but amount is 0 (mismatch: should have positive amount if source is yes)
              EarnedAmount: 0,
            )
            @report = setup_report([@project.id])
          end

          it 'flags cash income mismatch' do
            expect_result(title: 'Cash Income Matches Expected Value at Annual Assessment', invalid_count: 1)
          end
        end

        context 'with income no but cash sources present' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 0, # No
              total_monthly_income: 500, # But has income amount
              DataCollectionStage: 5, # Annual assessment
              Earned: 0, # No - but amount is positive (mismatch: should not have amount if source is no)
              EarnedAmount: 500,
            )
            @report = setup_report([@project.id])
          end

          it 'flags cash income mismatch' do
            expect_result(title: 'Cash Income Matches Expected Value at Annual Assessment', invalid_count: 1)
          end
        end
      end

      describe 'at Exit' do
        context 'with income yes but no cash sources' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 1, # Yes
              total_monthly_income: 0,
              DataCollectionStage: 3, # Exit
              Earned: 1, # Yes - but amount is 0 (mismatch: should have positive amount if source is yes)
              EarnedAmount: 0,
            )
            @report = setup_report([@project.id])
          end

          it 'flags cash income mismatch' do
            expect_result(title: 'Cash Income Matches Expected Value at Exit', invalid_count: 1)
          end
        end

        context 'with income no but cash sources present' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 0, # No
              total_monthly_income: 500, # But has income amount
              DataCollectionStage: 3, # Exit
              Earned: 0, # No - but amount is positive (mismatch: should not have amount if source is no)
              EarnedAmount: 500,
            )
            @report = setup_report([@project.id])
          end

          it 'flags cash income mismatch' do
            expect_result(title: 'Cash Income Matches Expected Value at Exit', invalid_count: 1)
          end
        end
      end
    end

    describe 'Non-Cash Benefits Matches Expected Value' do
      describe 'at Entry' do
        context 'with benefits yes but no NCB sources' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              benefits_from_any_source: 1, # Yes
              DataCollectionStage: 1, # Entry
              # No NCB sources set (mismatch: should have at least one NCB source if benefits_from_any_source is yes)
            )
            @report = setup_report([@project.id])
          end

          it 'flags NCB mismatch' do
            expect_result(title: 'Non-Cash Benefits Matches Expected Value at Entry', invalid_count: 1)
          end
        end

        context 'with benefits no but NCB sources present' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              benefits_from_any_source: 0, # No
              DataCollectionStage: 1, # Entry
              SNAP: 1, # Yes - but benefits_from_any_source is no (mismatch)
            )
            @report = setup_report([@project.id])
          end

          it 'flags NCB mismatch' do
            expect_result(title: 'Non-Cash Benefits Matches Expected Value at Entry', invalid_count: 1)
          end
        end
      end

      describe 'at Annual Assessment' do
        context 'with benefits yes but no NCB sources' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              benefits_from_any_source: 1, # Yes
              DataCollectionStage: 5, # Annual assessment
              # No NCB sources set (mismatch: should have at least one NCB source if benefits_from_any_source is yes)
            )
            @report = setup_report([@project.id])
          end

          it 'flags NCB mismatch' do
            expect_result(title: 'Non-Cash Benefits Matches Expected Value at Annual Assessment', invalid_count: 1)
          end
        end

        context 'with benefits no but NCB sources present' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              benefits_from_any_source: 0, # No
              DataCollectionStage: 5, # Annual assessment
              SNAP: 1, # Yes - but benefits_from_any_source is no (mismatch)
            )
            @report = setup_report([@project.id])
          end

          it 'flags NCB mismatch' do
            expect_result(title: 'Non-Cash Benefits Matches Expected Value at Annual Assessment', invalid_count: 1)
          end
        end
      end

      describe 'at Exit' do
        context 'with benefits yes but no NCB sources' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              benefits_from_any_source: 1, # Yes
              DataCollectionStage: 3, # Exit
              # No NCB sources set (mismatch: should have at least one NCB source if benefits_from_any_source is yes)
            )
            @report = setup_report([@project.id])
          end

          it 'flags NCB mismatch' do
            expect_result(title: 'Non-Cash Benefits Matches Expected Value at Exit', invalid_count: 1)
          end
        end

        context 'with benefits no but NCB sources present' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              benefits_from_any_source: 0, # No
              DataCollectionStage: 3, # Exit
              SNAP: 1, # Yes - but benefits_from_any_source is no (mismatch)
            )
            @report = setup_report([@project.id])
          end

          it 'flags NCB mismatch' do
            expect_result(title: 'Non-Cash Benefits Matches Expected Value at Exit', invalid_count: 1)
          end
        end
      end
    end

    describe 'Total Monthly Income Matches Sources' do
      describe 'at Entry' do
        context 'with total income not matching source amounts' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 1, # Yes
              total_monthly_income: 1000, # But source amounts sum to 200
              DataCollectionStage: 1, # Entry
              Earned: 1,
              EarnedAmount: 100,
              Unemployment: 1,
              UnemploymentAmount: 100,
            )
            @report = setup_report([@project.id])
          end

          it 'flags income amount mismatch' do
            expect_result(title: 'Total Monthly Income Matches Sources at Entry', invalid_count: 1)
          end
        end
      end

      describe 'at Exit' do
        context 'with total income not matching source amounts' do
          before do
            @project = create_project(project_type: 1) # ES
            @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
              income_from_any_source: 1, # Yes
              total_monthly_income: 1000, # But source amounts sum to 200
              DataCollectionStage: 3, # Exit
              Earned: 1,
              EarnedAmount: 100,
              Unemployment: 1,
              UnemploymentAmount: 100,
            )
            @report = setup_report([@project.id])
          end

          it 'flags income amount mismatch' do
            expect_result(title: 'Total Monthly Income Matches Sources at Exit', invalid_count: 1)
          end
        end
      end
    end

    describe 'Total Monthly Income at Exit' do
      context 'with income yes but no total monthly income' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
            income_from_any_source: 1, # Yes
            total_monthly_income: 0, # But no monthly income (mismatch)
            DataCollectionStage: 3, # Exit
          )
          @report = setup_report([@project.id])
        end

        it 'flags total monthly income mismatch' do
          expect_result(title: 'Total Monthly Income at Exit', invalid_count: 1)
        end
      end

      context 'with income no but has total monthly income' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
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
            income_from_any_source: 0, # No
            total_monthly_income: 500, # But has monthly income (mismatch)
            DataCollectionStage: 3, # Exit
          )
          @report = setup_report([@project.id])
        end

        it 'flags total monthly income mismatch' do
          expect_result(title: 'Total Monthly Income at Exit', invalid_count: 1)
        end
      end
    end
  end
end
