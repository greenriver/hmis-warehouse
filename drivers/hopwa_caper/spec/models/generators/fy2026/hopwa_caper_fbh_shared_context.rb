# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.shared_context 'FBH sheet shared context' do
  include_context 'HOPWA CAPER shared context'

  let(:project) do
    create_hopwa_project(funder: funder).tap do |p|
      p.update!(HousingType: 1, HOPWAMedAssistedLivingFac: 1, OperatingStartDate: report_start_date + 1.month)
      create(:hud_inventory, project: p, data_source: data_source, UnitInventory: 5, InventoryStartDate: report_start_date)
    end
  end

  let(:household_id) { Hmis::Hud::Base.generate_uuid }
  let(:hoh_client) { create(:hud_client, data_source: data_source) }

  let!(:hoh_enrollment) do
    create_hiv_positive_enrollment(
      client: hoh_client,
      project: project,
      entry_date: report_start_date + 1.day,
      household_id: household_id,
    )
  end

  let!(:leasing_service) do
    create(
      :hud_service,
      enrollment: hoh_enrollment,
      record_type: hopwa_financial_assistance,
      type_provided: 2, # Security deposits
      fa_amount: 500,
      date_provided: report_start_date + 1.week,
      data_source: data_source,
    )
  end

  let!(:income_benefit) do
    create(
      :hud_income_benefit,
      enrollment: hoh_enrollment,
      information_date: report_start_date + 1.day,
      IncomeFromAnySource: 1,
      Earned: 1,
      InsuranceFromAnySource: 1,
      Medicaid: 1,
      data_source: data_source,
    )
  end

  # For longevity tests
  let!(:prior_enrollment) do
    create_hiv_positive_enrollment(
      client: hoh_client,
      project: project,
      entry_date: report_start_date - 2.years,
      exit_date: report_start_date - 1.year,
      household_id: household_id,
    )
  end

  # For housing outcomes tests
  let(:exiting_client) { create(:hud_client, data_source: data_source) }
  let(:exiting_household_id) { Hmis::Hud::Base.generate_uuid }
  let!(:exiting_enrollment) do
    create_hiv_positive_enrollment(
      client: exiting_client,
      project: project,
      entry_date: report_start_date + 1.day,
      exit_date: report_start_date + 2.months,
      destination: hud_code(:destinations, 'Rental by client, no ongoing housing subsidy'),
      household_id: exiting_household_id,
    )
  end
end
