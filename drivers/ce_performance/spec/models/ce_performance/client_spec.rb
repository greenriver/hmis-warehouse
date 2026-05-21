###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CePerformance::Client, type: :model do
  let!(:report) { create(:simple_reports_report_instance, type: 'CePerformance::Report') }
  let!(:hud_client) { create(:grda_warehouse_hud_client) }

  def create_client(household_ages:)
    CePerformance::Client.create!(
      report_id: report.id,
      destination_client_id: hud_client.id,
      period: 'reporting',
      household_type: 'adults_only',
      household_ages: household_ages,
      head_of_household: true,
      q5a_b1: true,
    )
  end

  describe '.youth_only_households' do
    let!(:youth_client) { create_client(household_ages: [20]) }
    let!(:multi_age_youth_client) { create_client(household_ages: [18, 24]) }
    let!(:mixed_age_client) { create_client(household_ages: [17, 20]) }
    let!(:non_youth_client) { create_client(household_ages: [40]) }
    let!(:empty_ages_client) { create_client(household_ages: []) }

    it 'returns clients whose household ages are all within 18-24' do
      results = CePerformance::Client.served_in_period('reporting').youth_only_households
      expect(results.pluck(:id)).to contain_exactly(youth_client.id, multi_age_youth_client.id)
    end

    it 'excludes households with any member outside 18-24' do
      results = CePerformance::Client.served_in_period('reporting').youth_only_households
      expect(results.pluck(:id)).not_to include(mixed_age_client.id, non_youth_client.id)
    end

    it 'excludes households with empty ages' do
      results = CePerformance::Client.served_in_period('reporting').youth_only_households
      expect(results.pluck(:id)).not_to include(empty_ages_client.id)
    end
  end
end
