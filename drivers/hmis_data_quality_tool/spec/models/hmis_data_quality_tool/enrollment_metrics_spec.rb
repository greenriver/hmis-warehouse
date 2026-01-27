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

  describe 'Enrollment Metrics' do
    describe 'Disabling Condition Issues' do
      context 'with valid disabling condition' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          @enrollment.update(DisablingCondition: 1) # Yes
          @report = setup_report([@project.id])
        end

        it 'does not flag valid disabling condition' do
          expect_result(key: :disabling_condition_issues, invalid_count: 0)
        end
      end

      context 'with invalid disabling condition' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          @enrollment.update(DisablingCondition: nil) # Invalid value
          @report = setup_report([@project.id])
        end

        it 'flags disabling condition issues' do
          expect_result(key: :disabling_condition_issues, invalid_count: 1)
        end
      end
    end

    describe 'Living Situation Issues' do
      context 'with valid living situation for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 116, # Place not meant for habitation
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid living situation' do
          expect_result(key: :living_situation_issues, invalid_count: 0)
        end
      end

      context 'with invalid living situation' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 999, # Invalid value
          )
          @report = setup_report([@project.id])
        end

        it 'flags living situation issues' do
          expect_result(key: :living_situation_issues, invalid_count: 1)
        end
      end
    end

    describe 'Head of Household Issues' do
      context 'with valid single HoH' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1, # Head of household
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid HoH' do
          expect_result(key: :no_hoh_issues, invalid_count: 0)
          expect_result(key: :multiple_hoh_issues, invalid_count: 0)
        end
      end

      context 'with no HoH' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 2, # Not HoH
          )
          @report = setup_report([@project.id])
        end

        it 'flags no HoH issues' do
          expect_result(key: :no_hoh_issues, invalid_count: 1)
        end
      end

      context 'with multiple HoH in same household' do
        before do
          @project = create_project(project_type: 1) # ES
          @client1 = create_client_with_warehouse_link
          @client2 = create_client_with_warehouse_link
          household_id = 'test_household_123'
          create_enrollment(
            client: @client1,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
            household_id: household_id,
          )
          create_enrollment(
            client: @client2,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1, # Also HoH
            household_id: household_id,
          )
          @report = setup_report([@project.id])
        end

        it 'flags multiple HoH issues' do
          expect_result(key: :multiple_hoh_issues, total: 2, invalid_count: 2)
        end
      end
    end

    describe 'Exit Date Issues' do
      context 'with exit date after entry date' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid exit dates' do
          expect_result(key: :exit_date_issues, invalid_count: 0)
        end
      end

      context 'with exit date before entry date' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2022-10-15'.to_date, # Before entry
          )
          @report = setup_report([@project.id])
        end

        it 'flags exit date issues' do
          expect_result(key: :exit_date_issues, invalid_count: 1)
        end
      end
    end

    describe 'Destination Issues' do
      context 'with valid destination' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            destination: 8, # Emergency shelter
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid destinations' do
          expect_result(key: :destination_issues, invalid_count: 0)
        end
      end

      context 'with invalid destination' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            destination: 999, # Invalid value
          )
          @report = setup_report([@project.id])
        end

        it 'flags destination issues' do
          expect_result(key: :destination_issues, invalid_count: 1)
        end
      end
    end

    describe 'Future Date Issues' do
      context 'with future entry date' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: Date.tomorrow,
            exit_date: nil,
          )
          # Extend the report range to include future dates
          filter = default_filter.dup
          filter.update(
            project_ids: [@project.id],
            start: '2022-10-01'.to_date,
            end: Date.tomorrow + 1.day, # Extend end date to include tomorrow
          )
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
          @report = HmisDataQualityTool::Report.new(
            user_id: user_with_client_access.id,
            report_name: HmisDataQualityTool::Report.untranslated_title,
            manual: true,
            question_names: [],
          )
          @report.filter = filter
          @report.save!
          @report.run_and_save!
          @report.reload
        end

        it 'flags future entry date issues' do
          expect_result(key: :future_entry_date_issues, invalid_count: 1)
        end
      end

      context 'with future exit date' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: Date.tomorrow,
          )
          @report = setup_report([@project.id])
        end

        it 'flags future exit date issues' do
          expect_result(key: :future_exit_date_issues, invalid_count: 1)
        end
      end
    end

    describe 'Move-in Date Issues' do
      context 'with move-in date before entry date' do
        context 'for PSH project' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
            )
            @enrollment.update(MoveInDate: '2022-10-15'.to_date) # Before entry
            @report = setup_report([@project.id])
          end

          it 'flags move-in date issues' do
            expect_result(key: :move_in_prior_to_start_issues, invalid_count: 1)
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
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
            )
            @enrollment.update(MoveInDate: '2022-10-15'.to_date) # Before entry
            @report = setup_report([@project.id])
          end

          it 'flags move-in date issues' do
            expect_result(key: :move_in_prior_to_start_issues, invalid_count: 1)
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
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
            )
            @enrollment.update(MoveInDate: '2022-10-15'.to_date) # Before entry
            @report = setup_report([@project.id])
          end

          it 'flags move-in date issues' do
            expect_result(key: :move_in_prior_to_start_issues, invalid_count: 1)
          end
        end
      end

      context 'with move-in date after exit date' do
        context 'for PSH project' do
          before do
            @project = create_project(project_type: 3) # PSH
            @client = create_client_with_warehouse_link
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
            )
            @enrollment.update(MoveInDate: '2023-01-20'.to_date) # After exit
            @report = setup_report([@project.id])
          end

          it 'flags move-in date issues' do
            expect_result(key: :move_in_post_exit_issues, invalid_count: 1)
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
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
            )
            @enrollment.update(MoveInDate: '2023-01-20'.to_date) # After exit
            @report = setup_report([@project.id])
          end

          it 'flags move-in date issues' do
            expect_result(key: :move_in_post_exit_issues, invalid_count: 1)
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
            @enrollment = create_enrollment(
              client: @client,
              project: @project,
              entry_date: '2022-11-01'.to_date,
              exit_date: '2023-01-15'.to_date,
              relationship_to_ho_h: 1,
            )
            @enrollment.update(MoveInDate: '2023-01-20'.to_date) # After exit
            @report = setup_report([@project.id])
          end

          it 'flags move-in date issues' do
            expect_result(key: :move_in_post_exit_issues, invalid_count: 1)
          end
        end
      end
    end

    describe 'Enrollment Outside Project Operating Dates' do
      context 'with enrollment within operating dates' do
        before do
          @project = create_project(project_type: 1) # ES
          @project.update(
            OperatingStartDate: '2020-01-01'.to_date,
            OperatingEndDate: nil,
          )
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid operating dates' do
          expect_result(key: :enrollment_outside_project_operating_dates_issues, invalid_count: 0)
        end
      end

      context 'with enrollment before operating start date' do
        before do
          @project = create_project(project_type: 1) # ES
          @project.update(
            OperatingStartDate: '2023-01-01'.to_date,
            OperatingEndDate: nil,
          )
          @client = create_client_with_warehouse_link
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date, # Before operating start
            exit_date: '2023-01-15'.to_date,
          )
          @report = setup_report([@project.id])
        end

        it 'flags operating date issues' do
          expect_result(key: :enrollment_outside_project_operating_dates_issues, invalid_count: 1)
        end
      end
    end

    describe 'Unaccompanied Youth Issues' do
      context 'with unaccompanied youth under 12' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '2015-01-01'.to_date) # Age 7-8
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1, # Head of household (unaccompanied)
          )
          @report = setup_report([@project.id])
        end

        it 'flags unaccompanied youth under 12' do
          expect_result(key: :unaccompanied_youth_issues, invalid_count: 1)
        end
      end

      context 'with accompanied youth under 12' do
        before do
          @project = create_project(project_type: 1) # ES
          @adult = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @child = create_client_with_warehouse_link(dob: '2015-01-01'.to_date)
          household_id = 'test_household_123'
          create_enrollment(
            client: @adult,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
            household_id: household_id,
          )
          create_enrollment(
            client: @child,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 3, # Child
            household_id: household_id,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag accompanied youth' do
          expect_result(key: :unaccompanied_youth_issues, invalid_count: 0)
        end
      end
    end

    describe 'HoH Client Location Issues' do
      context 'with HoH missing enrollment CoC' do
        before do
          @project = create_project(project_type: 1, coc_code: 'MA-500')
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @enrollment.update(EnrollmentCoC: nil) # Missing CoC
          @report = setup_report([@project.id])
        end

        it 'flags missing enrollment CoC' do
          expect_result(key: :hoh_client_location_issues, invalid_count: 1)
        end
      end

      context 'with HoH enrollment CoC matching project CoC' do
        before do
          @project = create_project(project_type: 1, coc_code: 'MA-500')
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @enrollment.update(EnrollmentCoC: 'MA-500') # Matches project CoC
          @report = setup_report([@project.id])
        end

        it 'does not flag matching CoC' do
          expect_result(key: :hoh_client_location_issues, invalid_count: 0)
        end
      end
    end

    describe 'DV at Entry Issues' do
      context 'with missing DV data for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          create_health_and_dv(
            enrollment: @enrollment,
            information_date: '2022-11-01'.to_date,
            domestic_violence_survivor: 99, # Data not collected
          )
          @report = setup_report([@project.id])
        end

        it 'flags missing DV data' do
          expect_result(key: :dv_at_entry, invalid_count: 1)
        end
      end

      context 'with valid DV data for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          create_health_and_dv(
            enrollment: @enrollment,
            information_date: '2022-11-01'.to_date,
            domestic_violence_survivor: 0, # No
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid DV data' do
          expect_result(key: :dv_at_entry, invalid_count: 0)
        end
      end
    end

    describe 'Disability at Entry Collected Issues' do
      context 'with disabilities collected at entry' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          # Create disability at entry with valid response (not 99)
          create_disability(
            enrollment: @enrollment,
            information_date: '2022-11-01'.to_date,
            disability_type: 5, # Physical Disability
            disability_response: 0, # No
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag when disabilities are collected' do
          expect_result(key: :disability_at_entry_collected, invalid_count: 0)
        end
      end

      context 'with disabilities not collected at entry' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
          )
          # Create disability at entry with "Data not collected" (99)
          create_disability(
            enrollment: @enrollment,
            information_date: '2022-11-01'.to_date,
            disability_type: 5, # Physical Disability
            disability_response: 99, # Data not collected
          )
          @report = setup_report([@project.id])
        end

        it 'flags when disabilities are not collected' do
          expect_result(key: :disability_at_entry_collected, invalid_count: 1)
        end
      end
    end

    describe 'VAMC Station Issues' do
      context 'with valid VAMC station number' do
        before do
          @project = create_project(project_type: 0) # ES Entry/Exit
          # Add HUD-VASH funder (funder code 30)
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 30, # HUD: HUD-VASH
          )
          @client = create_client_with_warehouse_link(veteran_status: 1)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @enrollment.update(VAMCStation: '528') # Valid VAMC station
          @report = setup_report([@project.id])
        end

        it 'does not flag valid VAMC station' do
          expect_result(key: :vamc_station, invalid_count: 0)
        end
      end

      context 'with missing VAMC station number' do
        before do
          @project = create_project(project_type: 0) # ES Entry/Exit
          # Add HUD-VASH funder (funder code 30)
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 30, # HUD: HUD-VASH
          )
          @client = create_client_with_warehouse_link(veteran_status: 1)
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @enrollment.update(VAMCStation: nil) # Missing VAMC station
          @report = setup_report([@project.id])
        end

        it 'flags missing VAMC station' do
          expect_result(key: :vamc_station, invalid_count: 1)
        end
      end
    end

    describe 'No Veteran in Household Issues' do
      context 'with veteran in household' do
        before do
          @project = create_project(project_type: 12) # HP
          # Add VA: SSVF funder (funder code 33)
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 33, # VA: SSVF
          )
          @client = create_client_with_warehouse_link(veteran_status: 1)
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag when veteran is in household' do
          expect_result(key: :no_veteran_in_household, invalid_count: 0)
        end
      end

      context 'with no veteran in household' do
        before do
          @project = create_project(project_type: 12) # HP
          # Add VA: SSVF funder (funder code 33)
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 33, # VA: SSVF
          )
          @client = create_client_with_warehouse_link(veteran_status: 0) # Not a veteran
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'flags when no veteran is in household' do
          expect_result(key: :no_veteran_in_household, invalid_count: 1)
        end
      end
    end

    describe 'HoH Not Veteran Issues' do
      context 'with HoH who is a veteran' do
        before do
          @project = create_project(project_type: 12) # HP
          # Add VA: SSVF funder (funder code 33)
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 33, # VA: SSVF
          )
          @client = create_client_with_warehouse_link(veteran_status: 1)
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag when HoH is a veteran' do
          expect_result(key: :hoh_not_veteran, invalid_count: 0)
        end
      end

      context 'with HoH who is not a veteran' do
        before do
          @project = create_project(project_type: 12) # HP
          # Add VA: SSVF funder (funder code 33)
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 33, # VA: SSVF
          )
          @client = create_client_with_warehouse_link(veteran_status: 0) # Not a veteran
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: '2022-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            relationship_to_ho_h: 1,
          )
          @report = setup_report([@project.id])
        end

        it 'flags when HoH is not a veteran' do
          expect_result(key: :hoh_not_veteran, invalid_count: 1)
        end
      end
    end

    describe 'Date to Street Issues' do
      context 'with valid date to street' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
            living_situation: 116, # Place not meant for habitation (homeless)
            date_to_street_essh: report_end - 90.days, # Valid date
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag when date to street is present' do
          expect_result(key: :date_to_street_issues, invalid_count: 0)
        end
      end

      context 'with missing date to street' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
            living_situation: 116, # Place not meant for habitation (homeless)
            date_to_street_essh: nil, # Missing date
          )
          @report = setup_report([@project.id])
        end

        it 'flags when date to street is missing' do
          expect_result(key: :date_to_street_issues, invalid_count: 1)
        end
      end
    end

    describe 'Times Homeless Issues' do
      context 'with valid times homeless' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
            living_situation: 116, # Place not meant for habitation (homeless)
            date_to_street_essh: report_end - 90.days,
          )
          @enrollment.update(TimesHomelessPastThreeYears: 2) # Valid value
          @report = setup_report([@project.id])
        end

        it 'does not flag when times homeless is present' do
          expect_result(key: :times_homeless_issues, invalid_count: 0)
        end
      end

      context 'with missing times homeless' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
            living_situation: 116, # Place not meant for habitation (homeless)
            date_to_street_essh: report_end - 90.days,
          )
          @enrollment.update(TimesHomelessPastThreeYears: 99) # Data not collected
          @report = setup_report([@project.id])
        end

        it 'flags when times homeless is missing' do
          expect_result(key: :times_homeless_issues, invalid_count: 1)
        end
      end
    end

    describe 'Months Homeless Issues' do
      context 'with valid months homeless' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
            living_situation: 116, # Place not meant for habitation (homeless)
            date_to_street_essh: report_end - 90.days,
          )
          @enrollment.update(MonthsHomelessPastThreeYears: 12) # Valid value
          @report = setup_report([@project.id])
        end

        it 'does not flag when months homeless is present' do
          expect_result(key: :months_homeless_issues, invalid_count: 0)
        end
      end

      context 'with missing months homeless' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
            living_situation: 116, # Place not meant for habitation (homeless)
            date_to_street_essh: report_end - 90.days,
          )
          @enrollment.update(MonthsHomelessPastThreeYears: 99) # Data not collected
          @report = setup_report([@project.id])
        end

        it 'flags when months homeless is missing' do
          expect_result(key: :months_homeless_issues, invalid_count: 1)
        end
      end
    end

    describe 'Entry Date Entry Issues' do
      context 'with timely entry date entry' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
          )
          # Set DateCreated to be within threshold (e.g., 5 days after entry)
          @enrollment.update(DateCreated: @enrollment.EntryDate + 5.days)
          @report = setup_report([@project.id])
        end

        it 'does not flag timely entry date entry' do
          expect_result(key: :entry_date_entry_issues, invalid_count: 0)
        end
      end

      context 'with untimely entry date entry' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
          )
          # Set DateCreated to be well beyond threshold (e.g., 100 days after entry)
          @enrollment.update(DateCreated: @enrollment.EntryDate + 100.days)
          @report = setup_report([@project.id])
        end

        it 'flags untimely entry date entry' do
          expect_result(key: :entry_date_entry_issues, invalid_count: 1)
        end
      end
    end

    describe 'Current Living Situation Issues' do
      context 'with valid current living situation' do
        before do
          @project = create_project(project_type: 4) # SO
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: nil,
          )
          # Create valid current living situation
          create(
            :hud_current_living_situation,
            enrollment: @enrollment,
            data_source: data_source,
            PersonalID: @client.personal_id,
            InformationDate: report_end - 30.days,
            CurrentLivingSituation: 101, # Emergency shelter
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag valid current living situation' do
          expect_result(key: :current_living_situation_issues, invalid_count: 0)
        end
      end

      context 'with invalid current living situation' do
        before do
          @project = create_project(project_type: 4) # SO
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: nil,
          )
          # Create invalid current living situation
          create(
            :hud_current_living_situation,
            enrollment: @enrollment,
            data_source: data_source,
            PersonalID: @client.personal_id,
            InformationDate: report_end - 30.days,
            CurrentLivingSituation: 999, # Invalid value
          )
          @report = setup_report([@project.id])
        end

        it 'flags invalid current living situation' do
          expect_result(key: :current_living_situation_issues, invalid_count: 1)
        end
      end
    end

    describe 'Exit Date Entry Issues' do
      context 'with timely exit date entry' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
          )
          # Set exit DateCreated to be within threshold (e.g., 5 days after exit)
          exit_record = @enrollment.exit
          exit_record.update(DateCreated: exit_record.ExitDate + 5.days)
          @report = setup_report([@project.id])
        end

        it 'does not flag timely exit date entry' do
          expect_result(key: :exit_date_entry_issues, invalid_count: 0)
        end
      end

      context 'with untimely exit date entry' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 60.days,
            exit_date: report_end - 30.days,
          )
          # Set exit DateCreated to be well beyond threshold (e.g., 100 days after exit)
          exit_record = @enrollment.exit
          exit_record.update(DateCreated: exit_record.ExitDate + 100.days)
          @report = setup_report([@project.id])
        end

        it 'flags untimely exit date entry' do
          expect_result(key: :exit_date_entry_issues, invalid_count: 1)
        end
      end
    end

    describe 'Annual Assessment Issues' do
      context 'with complete annual assessments' do
        before do
          @project = create_project(project_type: 3) # PSH
          @client = create_client_with_warehouse_link
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
          # Create income benefit at annual assessment (on anniversary date, within valid window)
          create(
            :hud_income_benefit,
            enrollment: @enrollment,
            data_source: data_source,
            InformationDate: anniversary_date, # On anniversary date (within 30-day window)
            DataCollectionStage: 5, # Annual assessment
            IncomeFromAnySource: 0, # No
          )
          @report = setup_report([@project.id])
        end

        it 'does not flag when annual assessments are complete' do
          expect_result(key: :annual_assessment_issues, invalid_count: 0)
        end
      end

      context 'with missing annual assessments' do
        before do
          @project = create_project(project_type: 3) # PSH
          @client = create_client_with_warehouse_link
          report_end = default_filter.end
          # Create enrollment that started more than a year ago
          @enrollment = create_enrollment(
            client: @client,
            project: @project,
            entry_date: report_end - 400.days, # More than a year
            exit_date: nil,
            relationship_to_ho_h: 1,
          )
          # No annual assessment records created
          @report = setup_report([@project.id])
        end

        it 'flags when annual assessments are missing' do
          expect_result(key: :annual_assessment_issues, invalid_count: 1)
        end
      end
    end
  end
end
