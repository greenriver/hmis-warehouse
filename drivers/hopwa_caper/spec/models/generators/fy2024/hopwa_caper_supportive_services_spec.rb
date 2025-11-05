###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'

RSpec.describe 'HOPWA CAPER Supportive Services', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  let(:case_management_code) { supportive_service_types.invert.fetch('Case management') }
  let(:substance_use_code) { supportive_service_types.invert.fetch('Substance use services/treatment') }
  let(:transportation_code) { supportive_service_types.invert.fetch('Transportation') }

  context 'with multiple households receiving supportive services' do
    let!(:household_with_multiple_services) do
      create_hopwa_eligible_household(project: project)
    end

    let!(:secondary_household) do
      create_hopwa_eligible_household(project: project)
    end

    before do
      create_service(
        record_type: hopwa_supportive_service,
        enrollment: household_with_multiple_services.hoh,
        type_provided: case_management_code,
        fa_amount: 120,
      )

      create_service(
        record_type: hopwa_supportive_service,
        enrollment: household_with_multiple_services.hoh,
        type_provided: substance_use_code,
        fa_amount: 80,
      )

      create_service(
        record_type: hopwa_supportive_service,
        enrollment: secondary_household.hoh,
        type_provided: transportation_code,
        fa_amount: 15,
      )
    end

    it 'reports households and expenditures by supportive service type with deduplicated totals' do
      report = create_report([project])
      run_report(report)

      rows = question_as_rows(question_number: 'Q6', report: report)
      indexed = rows.to_h { |row| [row[0], row[1..]] }

      expect(indexed.fetch('Case Management')).to eq([1, 120])
      expect(indexed.fetch('Alcohol-Drug Abuse')).to eq([1, 80])
      expect(indexed.fetch('Transportation')).to eq([1, 15])
      expect(indexed.fetch('How many households received more than one type of Supportive Services?').first).to eq(1)
      expect(indexed.fetch('Deduplicated Supportive Services Household Total (based on amounts reported in Rows 5-21 above)').first).to eq(2)
    end
  end
end
