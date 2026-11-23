###
# Copyright Green River Data Group, Inc.
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
      context 'for PSH project' do
        before do
          @project = create_project(project_type: 3) # PSH
          report_end = default_filter.end

          [60, 90, 180, 365].each do |days|
            client = create_client_with_warehouse_link
            entry_date = report_end - days.days
            create_enrollment(
              client: client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
              move_in_date: days == 60 ? entry_date + 14.days : nil, # Only the 60 day enrollment has a move-in date
            )
          end

          @report = setup_report([@project.id])
        end

        it 'flags missing move-in date and does not flag valid move-in dates' do
          expect_result(key: :days_in_ph_prior_to_move_in_90_issues, total: 4, invalid_count: 3)
          expect_result(key: :days_in_ph_prior_to_move_in_180_issues, total: 4, invalid_count: 2)
          expect_result(key: :days_in_ph_prior_to_move_in_365_issues, total: 4, invalid_count: 1)
        end
      end

      context 'for SSO project with VA: GPD CM/HR funder' do
        before do
          @project = create_project(project_type: 6) # SSO
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 45, # VA: Grant Per Diem - Case Management/Housing Retention
          )
          report_end = default_filter.end

          [60, 90, 180, 365].each do |days|
            client = create_client_with_warehouse_link
            entry_date = report_end - days.days
            create_enrollment(
              client: client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
              move_in_date: days == 60 ? entry_date + 14.days : nil, # Only the 60 day enrollment has a move-in date
            )
          end

          @report = setup_report([@project.id])
        end

        it 'flags missing move-in date and does not flag valid move-in dates' do
          expect_result(key: :days_in_ph_prior_to_move_in_90_issues, total: 4, invalid_count: 3)
          expect_result(key: :days_in_ph_prior_to_move_in_180_issues, total: 4, invalid_count: 2)
          expect_result(key: :days_in_ph_prior_to_move_in_365_issues, total: 4, invalid_count: 1)
        end
      end

      context 'for Pay for Success project' do
        before do
          @project = create_project(project_type: 7) # Other
          create(
            :hud_funder,
            data_source: data_source,
            ProjectID: @project.ProjectID,
            Funder: 35, # HUD: Pay for Success
          )
          report_end = default_filter.end

          [60, 90, 180, 365].each do |days|
            client = create_client_with_warehouse_link
            entry_date = report_end - days.days
            create_enrollment(
              client: client,
              project: @project,
              entry_date: entry_date,
              exit_date: nil,
              relationship_to_ho_h: 1,
              move_in_date: days == 60 ? entry_date + 14.days : nil, # Only the 60 day enrollment has a move-in date
            )
          end

          @report = setup_report([@project.id])
        end

        it 'flags missing move-in date and does not flag valid move-in dates' do
          expect_result(key: :days_in_ph_prior_to_move_in_90_issues, total: 4, invalid_count: 3)
          expect_result(key: :days_in_ph_prior_to_move_in_180_issues, total: 4, invalid_count: 2)
          expect_result(key: :days_in_ph_prior_to_move_in_365_issues, total: 4, invalid_count: 1)
        end
      end
    end

    describe 'SO Missed Exit with households' do
      let(:report_end) { default_filter.end }
      let(:so_project) { create_project(project_type: 4) }
      let(:adult_dob) { report_end - 35.years }
      let(:child_dob) { report_end - 8.years }

      def create_cls(enrollment:, date:)
        create(
          :hud_current_living_situation,
          EnrollmentID: enrollment.EnrollmentID,
          PersonalID: enrollment.PersonalID,
          data_source_id: enrollment.data_source_id,
          InformationDate: date,
        )
      end

      def so_member(dob:, relationship:, household_id:, project: so_project, entry_date: report_end - 120.days, exit_date: nil)
        create_enrollment(
          client: create_client_with_warehouse_link(dob: dob),
          project: project,
          entry_date: entry_date,
          exit_date: exit_date,
          relationship_to_ho_h: relationship,
          household_id: household_id,
        )
      end

      it "does not flag a child without CLS when the HoH's last CLS is within 90 days" do
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a')
        create_cls(enrollment: hoh, date: report_end - 30.days)
        so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        @report = setup_report([so_project.id])

        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 0)
      end

      it 'flags a child whose HoH exited and whose own enrollment is still open' do
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a', exit_date: report_end - 100.days)
        create_cls(enrollment: hoh, date: report_end - 110.days)
        so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        @report = setup_report([so_project.id])

        # HoH has an exit date, so only the child can be flagged.
        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 1)
      end

      it 'flags an unaccompanied minor HoH with no CLS for 90+ days' do
        so_member(dob: report_end - 16.years, relationship: 1, household_id: 'hh-a')
        @report = setup_report([so_project.id])

        expect_result(key: :days_since_last_service_so_90_issues, total: 1, invalid_count: 1)
      end

      it "flags a non-HoH adult with no CLS even when the HoH's CLS is recent" do
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a')
        create_cls(enrollment: hoh, date: report_end - 30.days)
        so_member(dob: report_end - 30.years, relationship: 3, household_id: 'hh-a')
        @report = setup_report([so_project.id])

        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 1)
      end

      it 'flags an 18-year-old non-HoH with no CLS' do
        entry_date = report_end - 120.days
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a', entry_date: entry_date)
        create_cls(enrollment: hoh, date: report_end - 30.days)
        so_member(dob: entry_date - 18.years, relationship: 2, household_id: 'hh-a', entry_date: entry_date)
        @report = setup_report([so_project.id])

        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 1)
      end

      it "does not flag a child whose own last CLS is 90+ days old when the HoH's CLS is recent" do
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a')
        create_cls(enrollment: hoh, date: report_end - 30.days)
        child = so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        create_cls(enrollment: child, date: report_end - 100.days)
        @report = setup_report([so_project.id])

        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 0)
      end

      it "uses the child's own CLS when it is newer than the HoH's" do
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a')
        create_cls(enrollment: hoh, date: report_end - 100.days)
        child = so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        create_cls(enrollment: child, date: report_end - 30.days)
        @report = setup_report([so_project.id])

        # Only the HoH (last CLS 100 days ago) is flagged.
        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 1)
      end

      it "counts from the child's entry when the HoH's last CLS predates it" do
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a', entry_date: report_end - 200.days)
        create_cls(enrollment: hoh, date: report_end - 100.days)
        so_member(dob: child_dob, relationship: 2, household_id: 'hh-a', entry_date: report_end - 20.days)
        @report = setup_report([so_project.id])

        # Only the HoH (last CLS 100 days ago) is flagged; the child entered 20 days ago.
        expect_result(key: :days_since_last_service_so_90_issues, total: 2, invalid_count: 1)
      end

      it "does not use another household's HoH CLS" do
        other_hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-b')
        create_cls(enrollment: other_hoh, date: report_end - 30.days)
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a')
        create_cls(enrollment: hoh, date: report_end - 100.days)
        so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        @report = setup_report([so_project.id])

        # hh-a's HoH and child are both 100+ days out; hh-b's HoH is not.
        expect_result(key: :days_since_last_service_so_90_issues, total: 3, invalid_count: 2)
      end

      it 'does not use a HoH CLS from another data source with the same HouseholdID' do
        other_project = nil
        in_data_source(create(:source_data_source)) do
          other_project = create_project(project_type: 4)
          other_hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a', project: other_project)
          create_cls(enrollment: other_hoh, date: report_end - 30.days)
        end
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a')
        create_cls(enrollment: hoh, date: report_end - 100.days)
        so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        @report = setup_report([so_project.id, other_project.id])

        # This data source's HoH and child are both 100+ days out; the other data source's HoH is not.
        expect_result(key: :days_since_last_service_so_90_issues, total: 3, invalid_count: 2)
      end

      it 'does not use a HoH CLS from a project outside the report' do
        other_project = create_project(project_type: 4)
        hoh = so_member(dob: adult_dob, relationship: 1, household_id: 'hh-a', project: other_project)
        create_cls(enrollment: hoh, date: report_end - 30.days)
        so_member(dob: child_dob, relationship: 2, household_id: 'hh-a')
        @report = setup_report([so_project.id])

        # The HoH's project isn't in the report, so the child (no CLS, entered 120 days ago) is flagged.
        expect_result(key: :days_since_last_service_so_90_issues, total: 1, invalid_count: 1)
      end
    end
  end
end
