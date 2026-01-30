###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
include ArelHelper

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive, type: :model do
  describe 'project data quality V5' do
    let(:range) { ::Filters::DateRange.new(start: Date.parse('2016-01-01'), end: Date.parse('2016-12-31')) }
    let!(:data_source) { create(:grda_warehouse_data_source) }
    let!(:organization) { create(:hud_organization, data_source: data_source, OrganizationID: '3', OrganizationName: 'Test Organization') }
    let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectID: '148', ProjectType: 1) }

    # Test data counts:
    # - Total clients: 47
    # - Total enrollments: 47 (one per client)
    # - Sex complete: 20 (10 female, 10 male)
    # - Sex refused: 2 (8=don't know, 9=prefer not to answer)
    # - Sex not collected: 3 (99)
    # - Sex missing: 5 (nil)
    # - Name refused: 2, Name not collected: 2
    # - SSN refused: 3, SSN not collected: 10
    # - Enrollments with services: 25
    # - Enrollments with exits: 10 (5 to PH, 5 to non-PH)

    # Create clients with various sex values to test all scenarios
    # Sex Complete (Sex = 0 or 1): 20 clients
    let!(:clients_sex_female) { create_list(:grda_warehouse_hud_client, 10, data_source: data_source, Sex: 0, FirstName: 'Female', LastName: 'Client', SSN: '123456789') }
    let!(:clients_sex_male) { create_list(:grda_warehouse_hud_client, 10, data_source: data_source, Sex: 1, FirstName: 'Male', LastName: 'Client', SSN: '987654321') }

    # Sex Refused (Sex = 8 or 9): 2 clients
    let!(:clients_sex_refused) do
      [
        create(:grda_warehouse_hud_client, data_source: data_source, Sex: 8, FirstName: 'Refused', LastName: 'DontKnow', SSN: '111111111'),
        create(:grda_warehouse_hud_client, data_source: data_source, Sex: 9, FirstName: 'Refused', LastName: 'PreferNot', SSN: '222222222'),
      ]
    end

    # Sex Not Collected (Sex = 99): 3 clients
    let!(:clients_sex_not_collected) { create_list(:grda_warehouse_hud_client, 3, data_source: data_source, Sex: 99, FirstName: 'NotCollected', LastName: 'Client', SSN: '333333333') }

    # Sex Missing (Sex = nil): 5 clients
    let!(:clients_sex_missing) { create_list(:grda_warehouse_hud_client, 5, data_source: data_source, Sex: nil, FirstName: 'Missing', LastName: 'Client', SSN: '444444444') }

    # Name testing: 2 refused, 2 not collected
    let!(:clients_name_refused) { create_list(:grda_warehouse_hud_client, 2, data_source: data_source, Sex: 1, NameDataQuality: 9, FirstName: 'NameRefused', LastName: 'Client') }
    let!(:clients_name_not_collected) { create_list(:grda_warehouse_hud_client, 2, data_source: data_source, Sex: 0, NameDataQuality: 99, FirstName: 'NameNotCollected', LastName: 'Client') }

    # SSN testing: 3 refused, 10 not collected
    let!(:clients_ssn_refused) { create_list(:grda_warehouse_hud_client, 3, data_source: data_source, Sex: 1, SSNDataQuality: 8, FirstName: 'SSNRefused', LastName: 'Client') }
    let!(:clients_ssn_not_collected) { create_list(:grda_warehouse_hud_client, 10, data_source: data_source, Sex: 0, SSNDataQuality: 99, FirstName: 'SSNNotCollected', LastName: 'Client') }

    # Collect all clients (total: 20 + 2 + 3 + 5 + 2 + 2 + 3 + 10 = 47 clients)
    let(:all_clients) do
      clients_sex_female + clients_sex_male +
        clients_sex_refused +
        clients_sex_not_collected + clients_sex_missing +
        clients_name_refused + clients_name_not_collected +
        clients_ssn_refused + clients_ssn_not_collected
    end

    # Create enrollments for all 47 clients
    let!(:enrollments) do
      all_clients.map do |client|
        create(
          :grda_warehouse_hud_enrollment,
          data_source: data_source,
          ProjectID: project.ProjectID,
          PersonalID: client.PersonalID,
          EntryDate: range.start + 15.days,
          DateCreated: Time.current,
        )
      end
    end

    # Create services for exactly 25 enrollments (first 25) within the last 30 days
    let!(:services) do
      enrollments.first(25).map do |enrollment|
        create(
          :hud_service,
          data_source: data_source,
          EnrollmentID: enrollment.EnrollmentID,
          PersonalID: enrollment.PersonalID,
          DateProvided: range.end - 15.days,
        )
      end
    end

    # Create exits for exactly 10 enrollments (last 10)
    # 5 to permanent housing (PH), 5 to non-permanent destinations
    let!(:exits) do
      permanent_dests = HudHelper.util.permanent_destinations.first(5)
      non_permanent_dests = (HudHelper.util.homeless_destinations + HudHelper.util.temporary_destinations).first(5)

      enrollments.last(10).map.with_index do |enrollment, index|
        destination = if index < 5
          # First 5: Permanent destinations from HudHelper
          permanent_dests[index]
        else
          # Last 5: Non-permanent destinations from HudHelper
          non_permanent_dests[index - 5]
        end

        create(
          :hud_exit,
          data_source: data_source,
          EnrollmentID: enrollment.EnrollmentID,
          PersonalID: enrollment.PersonalID,
          ExitDate: range.end - 5.days,
          Destination: destination,
          DateCreated: Time.current,
        )
      end
    end

    describe 'a single project report' do
      let!(:report) do
        create(
          :data_quality_report_version_five,
          project: project,
          start: range.start,
          end: range.end,
        ).tap(&:run!)
      end
      it 'loads clients with enrollments open during the report range' do
        open_enrollments = included_enrollments.distinct.select(:PersonalID).count
        client_count = report.source_enrollments.distinct.select(:PersonalID).count

        aggregate_failures 'checking counts' do
          expect(client_count).to eq 47
          expect(client_count).to eq open_enrollments
        end
      end

      it 'creates equivalent report_enrollments' do
        open_enrollments = included_enrollments.distinct.select(:EnrollmentID).count
        report_enrollments = report.enrollments.count

        aggregate_failures 'checking counts' do
          expect(report_enrollments).to eq 47
          expect(open_enrollments).to eq report_enrollments
        end
      end

      it 'name refused' do
        key = :name
        enrollment_count = report.enrollments.where(name_refused: true).count
        enrollment_denominator = report.enrollments.count
        source_client_count = enrolled_clients.where(NameDataQuality: [8, 9]).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]["Don't Know / Refused"][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 2
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'name not collected' do
        key = :name
        enrollment_count = report.enrollments.where(name_not_collected: true).count
        enrollment_denominator = report.enrollments.count
        source_client_count = enrolled_clients.where(NameDataQuality: [99]).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 2
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'ssn refused' do
        key = :ssn
        enrollment_count = report.enrollments.where(ssn_refused: true).count
        enrollment_denominator = report.enrollments.count
        source_client_count = enrolled_clients.where(SSNDataQuality: [8, 9]).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]["Don't Know / Refused"][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 3
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'ssn not collected' do
        key = :ssn
        enrollment_count = report.enrollments.where(ssn_not_collected: true).count
        enrollment_denominator = report.enrollments.count
        source_client_count = enrolled_clients.where(SSNDataQuality: [99]).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 10
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'sex refused' do
        key = :sex
        enrollment_count = report.enrollments.where(sex_refused: true).count
        enrollment_denominator = report.enrollments.count

        source_client_count = enrolled_clients.where(Sex: [8, 9]).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]["Don't Know / Refused"][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 2
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'sex not collected' do
        key = :sex
        enrollment_count = report.enrollments.where(sex_not_collected: true).count
        enrollment_denominator = report.enrollments.count

        source_client_count = enrolled_clients.where(Sex: 99).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 3
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'sex missing' do
        key = :sex
        enrollment_count = report.enrollments.where(sex_missing: true).count
        enrollment_denominator = report.enrollments.count

        source_client_count = enrolled_clients.where(Sex: nil).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Missing / Null'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 5
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'sex complete' do
        key = :sex
        enrollment_count = report.enrollments.where(sex_complete: true).count
        enrollment_denominator = report.enrollments.count

        source_client_count = enrolled_clients.where(Sex: [0, 1]).count

        report_percentages = report.project_completeness(hud_project: project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Complete'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 37
          expect(enrollment_count).to eq source_client_count
          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'exiting clients' do
        aggregate_failures 'checking counts' do
          expect(exiting_clients.count).to eq 10
          expect(exiting_clients.count).to eq report.enrollments.exited.count
          expect(exiting_clients.pluck(:id).sort).to eq report.enrollments.exited.pluck(:client_id).sort
        end
      end

      it 'exits to ph' do
        source_clients = exiting_clients.where(ex_t[:Destination].in(HudHelper.util.permanent_destinations))
        exits = report.enrollments.exited.where(destination_id: HudHelper.util.permanent_destinations)

        aggregate_failures 'checking counts' do
          expect(source_clients.count).to eq 5
          expect(source_clients.count).to eq exits.count
        end
      end

      it 'no service in the past month' do
        source_with_service_count = enrolled_clients.
          joins(:services).
          merge(
            GrdaWarehouse::Hud::Service.where(DateProvided: (range.end - 30.days..range.end)),
          ).
          distinct.
          count
        with_service_count = report.enrollments.where(service_within_last_30_days: true).count

        aggregate_failures 'checking counts' do
          expect(source_with_service_count).to eq 25
          expect(with_service_count).to eq 25
          expect(source_with_service_count).to eq with_service_count
        end
      end
    end

    def included_enrollments
      GrdaWarehouse::Hud::Enrollment.
        open_during_range(range).
        where(ProjectID: report.project.ProjectID)
    end

    def enrolled_clients
      GrdaWarehouse::Hud::Client.joins(:enrollments).
        merge(
          GrdaWarehouse::Hud::Enrollment.open_during_range(range).
            where(ProjectID: report.project.ProjectID),
        )
    end

    def exiting_clients
      GrdaWarehouse::Hud::Client.joins(enrollments: :exit).
        merge(
          GrdaWarehouse::Hud::Enrollment.open_during_range(range).
            where(ProjectID: report.project.ProjectID),
        ).
        merge(
          GrdaWarehouse::Hud::Exit.where(ExitDate: range.range),
        )
    end
  end
end
