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

  describe 'Enrollment Length Metrics' do
    describe 'ES Length of Stay Issues' do
      context 'with ES enrollment under 90 days' do
        before do
          @project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days, # Under 90 days from report end
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag short stays' do
          # Should not be flagged if under 90 days
          expect_result(key: :lot_es_90_issues, invalid_count: 0)
        end
      end

      context 'with ES enrollment over 90 days without exit' do
        before do
          @project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 100.days, # More than 90 days before report end
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'flags long ES stays' do
          expect_result(key: :lot_es_90_issues, invalid_count: 1)
        end
      end

      context 'with ES enrollment over 180 days without exit' do
        before do
          @project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 200.days, # More than 180 days before report end
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'flags very long ES stays' do
          expect_result(key: :lot_es_90_issues, invalid_count: 1)
          expect_result(key: :lot_es_180_issues, invalid_count: 1)
        end
      end

      context 'with ES enrollment over 365 days without exit' do
        before do
          @project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 400.days, # More than 180 days before report end
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'flags very long ES stays' do
          expect_result(key: :lot_es_90_issues, invalid_count: 1)
          expect_result(key: :lot_es_180_issues, invalid_count: 1)
          expect_result(key: :lot_es_365_issues, invalid_count: 1)
        end
      end
    end

    describe 'ES Night-by-Night Service Issues' do
      context 'with ES-NBN enrollment with recent service' do
        before do
          @project = create_project(project_type: 1) # ES-NBN
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 15.days,
            exit_date: nil, # Still active
          )
          # Add recent bed night service (within 90 days of report end)
          create_bed_night_service(enrollment: @enrollment, date: report_end - 15.days)
          @report = setup_report([@project.id])
        end

        it 'does not flag recent service' do
          expect_result(key: :days_since_last_service_es_90_issues, invalid_count: 0)
        end
      end

      context 'with ES-NBN enrollment without service for 90+ days' do
        before do
          @project = create_project(project_type: 1) # ES-NBN
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 100.days,
            exit_date: nil, # Still active
          )
          # Add old bed night service (more than 90 days before report end)
          create_bed_night_service(enrollment: @enrollment, date: report_end - 100.days)
          @report = setup_report([@project.id])
        end

        it 'flags missing service' do
          expect_result(key: :days_since_last_service_es_90_issues, invalid_count: 1)
        end
      end
    end

    describe 'SO Length of Stay Issues' do
      context 'with SO enrollment without CLS for 90+ days' do
        before do
          @project = create_project(project_type: 4) # SO
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 100.days,
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'flags long SO stays' do
          expect_result(key: :days_since_last_service_so_90_issues, invalid_count: 1)
        end
      end

      context 'with SO enrollment without CLS for 180+ days' do
        before do
          @project = create_project(project_type: 4) # SO
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 200.days,
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'flags long SO stays' do
          expect_result(key: :days_since_last_service_so_90_issues, invalid_count: 1)
          expect_result(key: :days_since_last_service_so_180_issues, invalid_count: 1)
        end
      end

      context 'with SO enrollment without CLS for 365+ days' do
        before do
          @project = create_project(project_type: 4) # SO
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 400.days,
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'flags long SO stays' do
          expect_result(key: :days_since_last_service_so_90_issues, invalid_count: 1)
          expect_result(key: :days_since_last_service_so_180_issues, invalid_count: 1)
          expect_result(key: :days_since_last_service_so_365_issues, invalid_count: 1)
        end
      end

      context 'with SO enrollment with CLS within 90 days of report end' do
        before do
          @project = create_project(project_type: 4) # SO
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: nil, # Still active
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid move-in dates' do
          expect_result(key: :days_since_last_service_so_90_issues, invalid_count: 0)
        end
      end
    end

    describe 'PH Move-in Date Issues' do
      context 'with enrollment without move-in date for 90+ days' do
        context 'for PSH project' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 100.days, # More than 90 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
          end
        end

        context 'for SSO project with VA: GPD CM/HR funder' do
          before do
            @project = create_project(project_type: 6) # SSO
            # Add VA: GPD Case Management/Housing Retention funder (funder code 45)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @project.ProjectID,
              Funder: 45, # VA: Grant Per Diem - Case Management/Housing Retention
            )
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 100.days, # More than 90 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
          end
        end

        context 'for Pay for Success project' do
          before do
            @project = create_project(project_type: 7) # Other
            # Add Pay for Success funder (funder code 35)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @project.ProjectID,
              Funder: 35, # HUD: Pay for Success
            )
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 100.days, # More than 90 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
          end
        end
      end

      context 'with enrollment without move-in date for 180+ days' do
        context 'for PSH project' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 200.days, # More than 180 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
            expect_result(key: :days_in_ph_prior_to_move_in_180_issues, invalid_count: 1)
          end
        end

        context 'for Pay for Success project' do
          before do
            @project = create_project(project_type: 7) # Other
            # Add Pay for Success funder (funder code 35)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @project.ProjectID,
              Funder: 35, # HUD: Pay for Success
            )
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 200.days, # More than 180 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
            expect_result(key: :days_in_ph_prior_to_move_in_180_issues, invalid_count: 1)
          end
        end
      end

      context 'with enrollment without move-in date for 365+ days' do
        context 'for PSH project' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 400.days, # More than 365 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
            expect_result(key: :days_in_ph_prior_to_move_in_180_issues, invalid_count: 1)
            expect_result(key: :days_in_ph_prior_to_move_in_365_issues, invalid_count: 1)
          end
        end

        context 'for Pay for Success project' do
          before do
            @project = create_project(project_type: 7) # Other
            # Add Pay for Success funder (funder code 35)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @project.ProjectID,
              Funder: 35, # HUD: Pay for Success
            )
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 400.days, # More than 365 days before report end
              exit_date: nil, # Still active
              relationship_to_ho_h: 1,
            )
            # No move-in date set
            @report = setup_report([@project.id])
          end

          it 'flags missing move-in date' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 1)
            expect_result(key: :days_in_ph_prior_to_move_in_180_issues, invalid_count: 1)
            expect_result(key: :days_in_ph_prior_to_move_in_365_issues, invalid_count: 1)
          end
        end
      end

      context 'with enrollment with valid move-in date' do
        context 'for PSH project' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            entry_date = report_end - 60.days
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
              move_in_date: entry_date + 14.days, # Move-in shortly after entry
            )
            @report = setup_report([@project.id])
          end

          it 'does not flag valid move-in dates' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 0)
          end
        end

        context 'for Pay for Success project' do
          before do
            @project = create_project(project_type: 7) # Other
            # Add Pay for Success funder (funder code 35)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @project.ProjectID,
              Funder: 35, # HUD: Pay for Success
            )
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            entry_date = report_end - 60.days
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
              move_in_date: entry_date + 14.days, # Move-in shortly after entry
            )
            @report = setup_report([@project.id])
          end

          it 'does not flag valid move-in dates' do
            expect_result(key: :days_in_ph_prior_to_move_in_90_issues, invalid_count: 0)
          end
        end
      end
    end
  end
end
