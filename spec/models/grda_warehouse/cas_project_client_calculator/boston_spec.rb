###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::CasProjectClientCalculator::Boston, type: :model do
  describe 'Days Homeless Calculations' do
    let!(:lookups) do
      [
        create(
          :assessment_answer_lookup,
          assessment_question: 'c_housing_assessment_name',
          response_code: 3,
          response_text: 'Pathways 2024',
        ),
        create(
          :assessment_answer_lookup,
          assessment_question: 'c_housing_assessment_name',
          response_code: 4,
          response_text: 'RRH-PSH Transfer 2024',
        ),
        create(
          :assessment_answer_lookup,
          assessment_question: 'c_housing_assessment_name',
          response_code: 5,
          response_text: 'Family Pathways 2024',
        ),
      ]
    end

    before(:all) do
      GrdaWarehouse::Utility.clear!
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: true,
        cas_sync_months: 1,
        cas_calculator: 'GrdaWarehouse::CasProjectClientCalculator::Boston',
        self_report_start_date: 2.years.ago,
      )
      @calculator = GrdaWarehouse::Config.get(:cas_calculator).constantize.new
      import_hmis_csv_fixture(
        'spec/fixtures/files/cas_sync/days_homeless_calculations',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'identifies assessments appropriately' do
      aggregate_failures do
        # Transfer Assessment
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '106871')
        value = @calculator.value_for_cas_project_client(client: client, column: :total_homeless_nights_unsheltered)
        expect(value).to eq(0)
        value = @calculator.value_for_cas_project_client(client: client, column: :assessment_score_for_cas)
        expect(value).to eq('4')
        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.transfer.to_a).to include(assessment)
      end
    end

    # # These are the fields we actually need to check
    # Spec for the calculation is here:
    # https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0
    # # From assessment
    # additional_homeless_nights_unsheltered
    # additional_homeless_nights_sheltered
    #
    # # From HMIS/Warehouse
    # calculated_homeless_nights_unsheltered
    # calculated_homeless_nights_sheltered
    #
    # # Calculated based on setup
    # total_homeless_nights_unsheltered
    # total_homeless_nights_sheltered
    #
    # # Actually days homeless (we extend it beyond 3 years for family pathways)
    # days_homeless_in_last_three_years_cached
    it 'counts days homeless as expected when no warehouse days and no self-certification' do
      aggregate_failures do
        # Individual Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
        # c_add_boston_nights_outside_pathways => 370
        # c_add_boston_nights_sheltered_pathways => 899
        # calculated_homeless_nights_unsheltered => 0
        # calculated_homeless_nights_sheltered => 0
        #
        # We expect 899 + 370 = 1,269 to be clamped to 548 since there is no certification
        # Additionally, we expect to count 370 unsheltered and 178 sheltered
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(370)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(178)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(548)

        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.pathways.to_a).to include(assessment)

        # Family Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
        # c_add_boston_nights_outside_pathways => 1000
        # c_add_boston_nights_sheltered_pathways => 1200
        # calculated_homeless_nights_unsheltered => 0
        # calculated_homeless_nights_sheltered => 0
        #
        # c_pathways_nights_sheltered_warehouse_added_total => 1000
        # c_pathways_nights_unsheltered_warehouse_added_total => 1200
        # We expect 1000 + 1200 = 2,200 to be clamped to 548 since there is no certification
        # Additionally, we expect to count 548 unsheltered and 0 sheltered
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(548)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(548)

        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.family_pathways.to_a).to include(assessment)
      end
    end

    it 'counts days homeless as expected when YES warehouse days and no self-certification' do
      aggregate_failures do
        allow(@calculator).to receive(:calculated_homeless_nights_unsheltered).and_return(100)
        allow(@calculator).to receive(:calculated_homeless_nights_sheltered).and_return(200)

        # Individual Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
        # c_add_boston_nights_outside_pathways => 370
        # c_add_boston_nights_sheltered_pathways => 899
        # calculated_homeless_nights_unsheltered => 100
        # calculated_homeless_nights_sheltered => 200
        #
        # Warehouse days first, prioritizing sheltered
        # 100 + 200 = 300
        # clamp to 1,096 - calculate available for self-report
        # 1,096 - 300 = 796
        # self-report, prioritizing unsheltered
        # min(796, 548) - 370 = 178
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(200)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(100)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(370)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(178)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(848)

        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.pathways.to_a).to include(assessment)

        # Family Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
        # c_add_boston_nights_outside_pathways => 1000
        # c_add_boston_nights_sheltered_pathways => 1200
        # calculated_homeless_nights_unsheltered => 100
        # calculated_homeless_nights_sheltered => 200
        #
        # Warehouse days first, prioritizing sheltered
        # 100 + 200 = 300

        # self-report, prioritizing unsheltered, leaving none for sheltered
        # 548 - 1000 = 0
        #

        # We expect 1000 + 1200 = 2,200 to be clamped to 548 since there is no certification
        # Additionally, we expect to count 548 unsheltered and 0 sheltered
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(200)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(100)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(548)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(848)

        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.family_pathways.to_a).to include(assessment)
      end
    end

    it 'counts days homeless as expected when no warehouse days and YES self-certification' do
      aggregate_failures do
        allow(@calculator).to receive(:ce_self_certification_client_ids).and_return(GrdaWarehouse::Hud::Client.destination.pluck(:id))

        # Individual Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
        # c_add_boston_nights_outside_pathways => 370
        # c_add_boston_nights_sheltered_pathways => 899
        # calculated_homeless_nights_unsheltered => 0
        # calculated_homeless_nights_sheltered => 0
        #
        # We expect 899 + 370 = 1,269 to be clamped to 1,096 since there is a certification
        # but individual pathways are limited to 3 years
        # Additionally, we expect to count 370 unsheltered and 726 sheltered

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(370)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(726)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(1_096)

        # Family Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
        # c_add_boston_nights_outside_pathways => 1000
        # c_add_boston_nights_sheltered_pathways => 1200
        # calculated_homeless_nights_unsheltered => 0
        # calculated_homeless_nights_sheltered => 0
        #
        # We expect 1000 + 1200 = 2,200 to not be clamped since there is a certification
        # Additionally, we expect to count 1000 unsheltered and 1200 sheltered

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(0)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(1_000)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(1_200)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(2_200)

        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.family_pathways.to_a).to include(assessment)
      end
    end

    it 'counts days homeless as expected when YES warehouse days and YES self-certification' do
      aggregate_failures do
        allow(@calculator).to receive(:ce_self_certification_client_ids).and_return(GrdaWarehouse::Hud::Client.destination.pluck(:id))
        allow(@calculator).to receive(:calculated_homeless_nights_unsheltered).and_return(300)
        allow(@calculator).to receive(:calculated_homeless_nights_sheltered).and_return(400)

        # Individual Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
        # c_add_boston_nights_outside_pathways => 370
        # c_add_boston_nights_sheltered_pathways => 899
        # calculated_homeless_nights_unsheltered => 300
        # calculated_homeless_nights_sheltered => 400
        #
        # Warehouse days first, prioritizing sheltered
        # 400 + 300 = 700
        # clamp to 1,096
        # 1,096 - 700 = 396
        # self-report, prioritizing unsheltered
        # 396 - 370 = 26

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(400)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(300)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(370)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(26)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(1_096)

        # Family Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
        # c_add_boston_nights_outside_pathways => 1000
        # c_add_boston_nights_sheltered_pathways => 1200
        # calculated_homeless_nights_unsheltered => 300
        # calculated_homeless_nights_sheltered => 400
        # c_pathways_nights_sheltered_warehouse_added_total => 1000
        # c_pathways_nights_unsheltered_warehouse_added_total => 1200
        # We expect 1000 + 1200 = 2,200 to not be clamped since there is a certification
        # Additionally, we expect to count 1000 unsheltered and 1200 sheltered self-report
        # and 700 more warehouse days
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(400)

        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(300)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(1_000)

        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(1_200)

        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(2_900)

        assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
        expect(GrdaWarehouse::Hud::Assessment.family_pathways.to_a).to include(assessment)
      end
    end

    it 'counts warehouse nights sheltered even when there is no assessment' do
      aggregate_failures do
        # Create a client with no assessment but with warehouse nights sheltered
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '101842')
        allow(client).to receive(:sheltered_days_homeless_last_three_years).and_return(100)
        allow(client).to receive(:unsheltered_days_homeless_last_three_years).and_return(50)
        allow(client.processed_service_history).to receive(:days_homeless_last_three_years).and_return(150)

        # Verify that warehouse nights are still counted
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_sheltered)
        expect(value).to eq(100)

        # Verify that warehouse nights are still counted
        value = @calculator.value_for_cas_project_client(client: client, column: :calculated_homeless_nights_unsheltered)
        expect(value).to eq(50)

        # Verify that warehouse nights are still counted
        value = @calculator.value_for_cas_project_client(client: client, column: :total_homeless_nights_sheltered)
        expect(value).to eq(100)

        # Verify that warehouse nights are still counted
        value = @calculator.value_for_cas_project_client(client: client, column: :total_homeless_nights_unsheltered)
        expect(value).to eq(50)

        # Verify that additional nights are 0 since there is no assessment
        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
        expect(value).to eq(0)

        # Verify that additional nights are 0 since there is no assessment
        value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
        expect(value).to eq(0)

        # Verify that total nights in the last 3 years is the sum of the warehouse nights
        value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
        expect(value).to eq(150)
      end
    end
  end
end
