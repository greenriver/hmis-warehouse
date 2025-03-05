###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::CasProjectClientCalculator::Boston, type: :model do
  describe 'Days Homeless Calculations' do
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
      # Transfer Assessment
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '106871')
      value = @calculator.value_for_cas_project_client(client: client, column: :total_homeless_nights_unsheltered)
      expect(value).to eq(0)
      # assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
      # expect(GrdaWarehouse::Hud::Assessment.transfer.to_a).to include(assessment)

      # # Individual Pathways
      # client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '114450')
      # value = @calculator.value_for_cas_project_client(client: client, column: :total_homeless_nights_unsheltered)
      # expect(value).to eq(500)
      # assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
      # expect(GrdaWarehouse::Hud::Assessment.pathways.to_a).to include(assessment)

      # # Family Pathways
      # client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '107404')
      # value = @calculator.value_for_cas_project_client(client: client, column: :total_homeless_nights_unsheltered)
      # expect(value).to eq(2_000)
      # assessment = client.most_recent_pathways_or_rrh_assessment_for_destination
      # expect(GrdaWarehouse::Hud::Assessment.family_pathways.to_a).to include(assessment)
    end
  end
end
