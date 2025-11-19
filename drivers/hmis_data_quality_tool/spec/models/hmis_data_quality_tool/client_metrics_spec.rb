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

  describe 'Client Metrics' do
    describe 'Name Issues' do
      context 'with valid name data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(
            first_name: 'John',
            last_name: 'Doe',
          )
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'does not flag valid names' do
          # Verify report completed successfully
          expect(@report.state).to eq('Completed')
          expect(@report.completed_at).not_to be_nil

          # Verify clients are found in the report
          expect(@report.clients.count).to be > 0

          expect_result(title: 'Name', invalid_count: 0)
        end
      end

      context 'with blank name but DQ indicates full name reported' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(
            first_name: nil,
            last_name: 'Doe',
            name_data_quality: 1, # Full name reported
          )
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags name issues' do
          expect_result(title: 'Name', invalid_count: 1)
        end
      end

      context 'with name present but DQ is data not collected' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(
            first_name: 'John',
            last_name: 'Doe',
          )
          @client.update(NameDataQuality: 99) # Data not collected
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags name issues' do
          expect_result(title: 'Name', invalid_count: 1)
        end
      end
    end

    describe 'SSN Issues' do
      context 'with valid SSN data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(ssn: '123456789')
          @client.update(SSNDataQuality: 1) # Full SSN reported
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'does not flag valid SSNs' do
          expect_result(title: 'Social Security Number', invalid_count: 0)
        end
      end

      context 'with blank SSN but DQ indicates full SSN reported' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(ssn: nil)
          @client.update(SSNDataQuality: 1) # Full SSN reported
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags SSN issues' do
          expect_result(title: 'Social Security Number', invalid_count: 1)
        end
      end

      context 'with SSN all zeros' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(ssn: '000000000')
          @client.update(SSNDataQuality: 1)
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags SSN issues' do
          expect_result(title: 'Social Security Number', invalid_count: 1)
        end
      end

      context 'with SSN present but DQ is data not collected' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(ssn: '112233445')
          @client.update(SSNDataQuality: 99) # Data not collected
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags SSN issues' do
          expect_result(title: 'Social Security Number', invalid_count: 1)
        end
      end
    end

    describe 'DOB Issues' do
      context 'with valid DOB' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @client.update(DOBDataQuality: 1)
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'does not flag valid DOBs' do
          expect_result(title: 'DOB', invalid_count: 0)
        end
      end

      context 'with blank DOB' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: nil)
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags DOB issues' do
          expect_result(title: 'DOB', invalid_count: 1)
        end
      end

      context 'with DOB before Oct 10 1910' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1910-10-09'.to_date)
          @client.update(DOBDataQuality: 1)
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags DOB issues' do
          expect_result(title: 'DOB', invalid_count: 1)
        end
      end

      context 'with DOB after entry date' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '2023-01-20'.to_date)
          @client.update(DOBDataQuality: 1)
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags DOB issues' do
          expect_result(title: 'DOB', invalid_count: 1)
        end
      end
    end

    describe 'Race Issues' do
      context 'with valid race data' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @client.update(
            AmIndAKNative: 1,
            Asian: 0,
            BlackAfAmerican: 0,
            NativeHIPacific: 0,
            White: 0,
            MidEastNAfrican: 0,
            HispanicLatinaeo: 0,
            RaceNone: nil,
          )
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'does not flag valid race data' do
          expect_result(title: 'Race', invalid_count: 0)
        end
      end

      context 'with race yes but RaceNone present' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @client.update(
            AmIndAKNative: 1,
            Asian: 0,
            BlackAfAmerican: 0,
            NativeHIPacific: 0,
            White: 0,
            MidEastNAfrican: 0,
            HispanicLatinaeo: 0,
            RaceNone: 1,
          )
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags race issues' do
          expect_result(title: 'Race', invalid_count: 1)
        end
      end

      context 'with all race no but RaceNone nil' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link
          @client.update(
            AmIndAKNative: 0,
            Asian: 0,
            BlackAfAmerican: 0,
            NativeHIPacific: 0,
            White: 0,
            MidEastNAfrican: 0,
            HispanicLatinaeo: 0,
            RaceNone: nil,
          )
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags race issues' do
          expect_result(title: 'Race', invalid_count: 1)
        end
      end
    end

    describe 'Veteran Status Issues' do
      context 'with valid veteran status for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @client.update(VeteranStatus: 1) # Yes
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'does not flag valid veteran status' do
          expect_result(title: 'Veteran Status', invalid_count: 0)
        end
      end

      context 'with missing veteran status for adult' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: '1990-01-01'.to_date)
          @client.update(VeteranStatus: 99) # Data not collected
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'flags veteran status issues' do
          expect_result(title: 'Veteran Status', invalid_count: 1)
        end
      end

      context 'with missing veteran status for child' do
        before do
          @project = create_project(project_type: 1) # ES
          @client = create_client_with_warehouse_link(dob: Date.current - 10.years)
          @client.update(VeteranStatus: 99) # Data not collected
          create_enrollment(client: @client, project: @project)
          @report = setup_report([@project.id])
        end

        it 'does not flag veteran status for children' do
          # Children are not in the denominator
          expect_result(title: 'Veteran Status', total: 0, invalid_count: 0)
        end
      end
    end
  end
end
