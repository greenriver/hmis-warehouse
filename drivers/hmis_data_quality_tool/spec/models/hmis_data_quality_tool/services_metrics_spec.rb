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

  describe 'Services Metrics' do
    describe 'Overlapping Entry/Exit Enrollments' do
      context 'with non-overlapping enrollments' do
        before do
          @es_project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2022-12-01'.to_date,
          )
          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2022-12-15'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          @report = setup_report([@es_project.id])
        end

        it 'does not flag non-overlapping enrollments' do
          expect_result(key: :overlapping_entry_exit_issues, invalid_count: 0)
        end
      end

      context 'with overlapping ES enrollments' do
        before do
          @es_project = create_project(project_type: 0) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2022-12-15'.to_date,
          )
          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2022-12-01'.to_date, # Overlaps with first
            exit_date: '2023-01-15'.to_date,
          )
          @report = setup_report([@es_project.id])
        end

        it 'flags overlapping enrollments' do
          expect_result(key: :overlapping_entry_exit_issues, invalid_count: 1)
        end
      end

      context 'with overlapping TH enrollments' do
        before do
          @th_project = create_project(project_type: 2) # TH
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @th_project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2022-12-15'.to_date,
          )
          create_enrollment(
            client: @client,
            project: @th_project,
            entry_date: '2022-12-01'.to_date, # Overlaps with first
            exit_date: '2023-01-15'.to_date,
          )
          @report = setup_report([@th_project.id])
        end

        it 'flags overlapping TH enrollments' do
          expect_result(key: :overlapping_entry_exit_issues, invalid_count: 1)
        end
      end
    end

    describe 'Overlapping Night-by-Night ES Enrollments' do
      context 'with overlapping NBN enrollments' do
        before do
          @nbn_project = create_project(project_type: 1) # ES-NBN
          @es_project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link
          @nbn_enrollment = create_enrollment(
            client: @client,
            project: @nbn_project,
            entry_date: '2022-12-14'.to_date,
            exit_date: '2022-12-15'.to_date,
          )
          @nbn_enrollment2 = create_enrollment(
            client: @client,
            project: @nbn_project,
            entry_date: '2022-12-17'.to_date,
            exit_date: '2022-12-18'.to_date,
          )
          @es_enrollment = create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2022-12-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          # Add overlapping bed night services on the same date
          create_bed_night_service(enrollment: @nbn_enrollment, date: '2022-12-14'.to_date)
          create_bed_night_service(enrollment: @nbn_enrollment2, date: '2022-12-17'.to_date)
          @report = setup_report([@nbn_project.id, @es_project.id])
        end

        it 'flags overlapping NBN enrollments' do
          expect_result(key: :overlapping_nbn_issues, invalid_count: 1)
        end
      end
    end

    describe 'Overlapping Post Move-in PH Enrollments' do
      context 'with overlapping PH enrollments after move-in' do
        context 'for PSH projects' do
          before do
            @ph_project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            @enrollment1 = create_enrollment(
              client: @client,
              project: @ph_project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
              move_in_date: '2022-11-15'.to_date,
            )
            @enrollment2 = create_enrollment(
              client: @client,
              project: @ph_project,
              entry_date: '2022-12-01'.to_date, # Overlaps with first after move-in
              exit_date: '2023-02-15'.to_date,
              relationship_to_ho_h: 1,
              move_in_date: '2022-12-15'.to_date,
            )
            @report = setup_report([@ph_project.id])
          end

          it 'flags overlapping PH enrollments' do
            expect_result(key: :overlapping_post_move_in_issues, invalid_count: 1)
          end
        end

        context 'for Pay for Success projects' do
          before do
            @pfs_project = create_project(project_type: 7) # Other
            # Add Pay for Success funder (funder code 35)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @pfs_project.ProjectID,
              Funder: 35, # HUD: Pay for Success
            )
            @client = create_client_with_warehouse_link
            @enrollment1 = create_enrollment(
              client: @client,
              project: @pfs_project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
              move_in_date: '2022-11-15'.to_date,
            )
            @enrollment2 = create_enrollment(
              client: @client,
              project: @pfs_project,
              entry_date: '2022-12-01'.to_date, # Overlaps with first after move-in
              exit_date: '2023-02-15'.to_date,
              relationship_to_ho_h: 1,
              move_in_date: '2022-12-15'.to_date,
            )
            @report = setup_report([@pfs_project.id])
          end

          it 'flags overlapping Pay for Success enrollments' do
            expect_result(key: :overlapping_post_move_in_issues, invalid_count: 1)
          end
        end
      end
    end

    describe 'Overlapping Homeless Service After Move-in in PH' do
      context 'with homeless service overlapping PH move-in' do
        context 'for PSH project' do
          before do
            @th_project = create_project(project_type: 2) # TH
            @ph_project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link

            @th_enrollment1 = create_enrollment(
              client: @client,
              project: @th_project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2022-12-15'.to_date,
            )
            @th_enrollment2 = create_enrollment(
              client: @client,
              project: @th_project,
              entry_date: '2022-11-02'.to_date,
              exit_date: '2022-12-15'.to_date,
            )
            @th_enrollment3 = create_enrollment(
              client: @client,
              project: @th_project,
              entry_date: '2022-11-03'.to_date,
              exit_date: '2022-12-15'.to_date,
            )
            @ph_enrollment = create_enrollment(
              client: @client,
              project: @ph_project,
              entry_date: '2022-11-15'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
              move_in_date: '2022-12-01'.to_date,
            )
            create_bed_night_service(enrollment: @th_enrollment1, date: '2022-12-02'.to_date)
            create_bed_night_service(enrollment: @th_enrollment2, date: '2022-12-03'.to_date)
            create_bed_night_service(enrollment: @th_enrollment3, date: '2022-12-04'.to_date)
            @report = setup_report([@th_project.id, @ph_project.id])
          end

          it 'flags overlapping homeless service after PH move-in' do
            expect_result(key: :overlapping_pre_move_in_issues, invalid_count: 1)
          end
        end

        context 'for Pay for Success project' do
          before do
            @th_project = create_project(project_type: 2) # TH
            @pfs_project = create_project(project_type: 7) # Other
            # Add Pay for Success funder (funder code 35)
            create(
              :hud_funder,
              data_source: data_source,
              ProjectID: @pfs_project.ProjectID,
              Funder: 35, # HUD: Pay for Success
            )
            @client = create_client_with_warehouse_link

            @th_enrollment1 = create_enrollment(
              client: @client,
              project: @th_project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2022-12-15'.to_date,
            )
            @th_enrollment2 = create_enrollment(
              client: @client,
              project: @th_project,
              entry_date: '2022-11-02'.to_date,
              exit_date: '2022-12-15'.to_date,
            )
            @th_enrollment3 = create_enrollment(
              client: @client,
              project: @th_project,
              entry_date: '2022-11-03'.to_date,
              exit_date: '2022-12-15'.to_date,
            )
            @pfs_enrollment = create_enrollment(
              client: @client,
              project: @pfs_project,
              entry_date: '2022-11-15'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
              move_in_date: '2022-12-01'.to_date,
            )
            create_bed_night_service(enrollment: @th_enrollment1, date: '2022-12-02'.to_date)
            create_bed_night_service(enrollment: @th_enrollment2, date: '2022-12-03'.to_date)
            create_bed_night_service(enrollment: @th_enrollment3, date: '2022-12-04'.to_date)
            @report = setup_report([@th_project.id, @pfs_project.id])
          end

          it 'flags overlapping homeless service after Pay for Success move-in' do
            expect_result(key: :overlapping_pre_move_in_issues, invalid_count: 1)
          end
        end
      end
    end

    describe 'ES Days Since Last Service' do
      describe '90 Days' do
        context 'with ES-NBN enrollment without service for 90+ days' do
          before do
            @project = create_project(project_type: 1) # ES-NBN
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 200.days,
              exit_date: nil, # Still active
            )
            # Add old bed night service (more than 90 days ago)
            create_bed_night_service(enrollment: @enrollment, date: report_end - 100.days)
            @report = setup_report([@project.id])
          end

          it 'flags missing service' do
            expect_result(key: :days_since_last_service_es_90_issues, invalid_count: 1)
          end
        end
      end

      describe '180 Days' do
        context 'with ES-NBN enrollment without service for 180+ days' do
          before do
            @project = create_project(project_type: 1) # ES-NBN
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 300.days,
              exit_date: nil, # Still active
            )
            # Add old bed night service (more than 180 days ago)
            create_bed_night_service(enrollment: @enrollment, date: report_end - 200.days)
            @report = setup_report([@project.id])
          end

          it 'flags missing service' do
            expect_result(key: :days_since_last_service_es_180_issues, invalid_count: 1)
          end
        end
      end

      describe '365 Days' do
        context 'with ES-NBN enrollment without service for 365+ days' do
          before do
            @project = create_project(project_type: 1) # ES-NBN
            @client = create_client_with_warehouse_link
            report_end = default_filter.end
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: report_end - 500.days,
              exit_date: nil, # Still active
            )
            # Add old bed night service (more than 365 days ago)
            create_bed_night_service(enrollment: @enrollment, date: report_end - 400.days)
            @report = setup_report([@project.id])
          end

          it 'flags missing service' do
            expect_result(key: :days_since_last_service_es_365_issues, invalid_count: 1)
          end
        end
      end
    end

    describe 'HP - Homeless Prior Living Situation' do
      context 'with homeless living situation in HP project' do
        before do
          @project = create_project(project_type: 12) # HP
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 116, # Place not meant for habitation (homeless)
          )
          @report = setup_report([@project.id])
        end

        it 'flags homeless living situation' do
          expect_result(key: :homeless_living_situation_issues, invalid_count: 1)
        end
      end

      context 'with non-homeless living situation in HP project' do
        before do
          @project = create_project(project_type: 12) # HP
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 410, # Rental by client, no ongoing housing subsidy (non-homeless)
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag non-homeless living situation' do
          expect_result(key: :homeless_living_situation_issues, invalid_count: 0)
        end
      end
    end

    describe 'RRH - Non-Homeless Prior Living Situation' do
      context 'with non-homeless living situation in RRH project' do
        before do
          @project = create_project(project_type: 13) # RRH
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 410, # Rental by client, no ongoing housing subsidy (non-homeless)
          )
          @report = setup_report([@project.id])
        end

        it 'flags non-homeless living situation' do
          expect_result(key: :non_homeless_living_situation_issues, invalid_count: 1)
        end
      end

      context 'with homeless living situation in RRH project' do
        before do
          @project = create_project(project_type: 13) # RRH
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 116, # Place not meant for habitation (homeless)
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag homeless living situation' do
          expect_result(key: :non_homeless_living_situation_issues, invalid_count: 0)
        end
      end
    end
  end
end
