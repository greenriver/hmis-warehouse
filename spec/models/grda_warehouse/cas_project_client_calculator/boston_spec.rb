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

        # Individual Pathways
        client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
        # c_pathways_nights_sheltered_warehouse_added_total => 899
        # c_pathways_nights_unsheltered_warehouse_added_total => 370
        # We expect 899 + 370 = 1,269 to be clamped to 548 since there is no certification
        # Additionally, we expect to count 370 unsheltered and 178 sheltered

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
        # c_pathways_nights_sheltered_warehouse_added_total => 1000
        # c_pathways_nights_unsheltered_warehouse_added_total => 1200
        # We expect 1000 + 1200 = 2,200 to be clamped to 548 since there is no certification
        # Additionally, we expect to count 548 unsheltered and 0 sheltered
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

    describe 'when clients have self-certifications' do
      it 'identifies assessments appropriately' do
        aggregate_failures do
          allow(@calculator).to receive(:ce_self_certification_client_ids).and_return(GrdaWarehouse::Hud::Client.destination.pluck(:id))

          # Individual Pathways
          client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
          # c_pathways_nights_sheltered_warehouse_added_total => 899
          # c_pathways_nights_unsheltered_warehouse_added_total => 370
          # We expect 899 + 370 = 1,269 to be clamped to 1,096 since there is a certification
          # but individual pathways are limited to 3 years
          # Additionally, we expect to count 370 unsheltered and 726 sheltered

          value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
          expect(value).to eq(370)

          value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
          expect(value).to eq(726)

          value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
          expect(value).to eq(1_096)

          # Family Pathways
          client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
          # c_pathways_nights_sheltered_warehouse_added_total => 1000
          # c_pathways_nights_unsheltered_warehouse_added_total => 1200
          # We expect 1000 + 1200 = 2,200 to not be clamped since there is a certification
          # Additionally, we expect to count 1000 unsheltered and 1200 sheltered
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
    end

    describe 'when clients have self-certifications AND Warehouse days' do
      it 'identifies assessments appropriately' do
        aggregate_failures do
          allow(@calculator).to receive(:ce_self_certification_client_ids).and_return(GrdaWarehouse::Hud::Client.destination.pluck(:id))
          allow(@calculator).to receive(:calculated_homeless_nights_unsheltered).and_return(300)
          allow(@calculator).to receive(:calculated_homeless_nights_sheltered).and_return(400)

          # Individual Pathways
          client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
          # c_pathways_nights_sheltered_warehouse_added_total => 899
          # c_pathways_nights_unsheltered_warehouse_added_total => 370
          # We expect 899 + 370 = 1,269 to be clamped to 1,096 since there is a certification
          # but individual pathways are limited to 3 years
          # Additionally, we expect to count 370 unsheltered and 726 sheltered

          # TODO: should we be limiting the self-report that is showing in CAS based on
          # warehouse days?
          value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_unsheltered)
          expect(value).to eq(370)

          value = @calculator.value_for_cas_project_client(client: client, column: :additional_homeless_nights_sheltered)
          expect(value).to eq(899)

          value = @calculator.value_for_cas_project_client(client: client, column: :days_homeless_in_last_three_years_cached)
          expect(value).to eq(1_096)

          # Family Pathways
          client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
          # c_pathways_nights_sheltered_warehouse_added_total => 1000
          # c_pathways_nights_unsheltered_warehouse_added_total => 1200
          # We expect 1000 + 1200 = 2,200 to not be clamped since there is a certification
          # Additionally, we expect to count 1000 unsheltered and 1200 sheltered self-report
          # and 700 more warehouse days
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
    end
  end
end
