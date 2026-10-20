###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohort length-of-time columns and the effective date', type: :model do
  let(:effective_date) { Date.current - 1.year }
  let(:client) { create :hud_client }
  let(:cohort) { create :cohort, effective_date: effective_date }
  let!(:cohort_client) { create :cohort_client, cohort: cohort, client: client }

  def add_days(dates, project_type:, homeless:, literally_homeless:, project: nil)
    she_attrs = { client: client, project_type: project_type }
    she_attrs.merge!(project_id: project.ProjectID, organization_id: project.OrganizationID, data_source_id: project.data_source_id) if project
    she = create(:she_entry, **she_attrs)
    Array.wrap(dates).each do |date|
      create(
        :service_history_service,
        client_id: client.id,
        service_history_enrollment_id: she.id,
        record_type: 'service',
        date: date,
        project_type: project_type,
        homeless: homeless,
        literally_homeless: literally_homeless,
      )
    end
  end

  before do
    # 10 ES days before the effective date, 5 after
    es_dates = (effective_date - 10.days..effective_date - 1.day).to_a + (effective_date + 1.day..effective_date + 5.days).to_a
    add_days(es_dates, project_type: 1, homeless: true, literally_homeless: true)
    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!

    # Nightly values as of today, which must not be used for an effective date in the past
    create(:grda_warehouse_warehouse_clients_processed, client_id: client.id, homeless_days: 15)
  end

  describe 'Cohort#refresh_time_dependant_client_data' do
    before do
      cohort.refresh_time_dependant_client_data
      cohort_client.reload
    end

    it 'calculates days homeless as of the effective date' do
      expect(cohort_client.calculated_days_homeless_on_effective_date).to eq(10)
    end
  end

  describe 'three-year counts' do
    # Inside the three years before the effective date, but more than three years before today
    let(:old_date) { effective_date - 2.years - 30.days }

    before do
      add_days([old_date, old_date + 1.day], project_type: 1, homeless: true, literally_homeless: true)
      # TH overlapping the first old ES day
      add_days([old_date], project_type: 2, homeless: true, literally_homeless: false)
      GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!

      cohort.refresh_time_dependant_client_data
      cohort_client.reload
    end

    # The 10 days before the effective date and both old days
    it 'calculates days homeless in the last three years as of the effective date' do
      expect(cohort_client.days_homeless_last_three_years_on_effective_date).to eq(12)
    end

    # The 10 days before the effective date and the old day without TH
    it 'calculates days literally homeless in the last three years as of the effective date' do
      expect(cohort_client.days_literally_homeless_last_three_years_on_effective_date).to eq(11)
    end
  end

  describe 'days homeless plus overrides' do
    let(:override_project) { create :hud_project, ProjectType: 6, include_in_days_homeless_override: true }

    before do
      # Verified-days override project: one day before the effective date, one after
      add_days([effective_date - 30.days, effective_date + 30.days], project_type: 6, homeless: nil, literally_homeless: nil, project: override_project)
      GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
      # Nightly value as of today: all 15 ES days and both override days
      GrdaWarehouse::WarehouseClientsProcessed.where(client_id: client.id).update_all(days_homeless_plus_overrides: 17)

      cohort.refresh_time_dependant_client_data
      cohort_client.reload
    end

    # The 10 ES days and the override day before the effective date
    it 'calculates days homeless plus overrides as of the effective date' do
      expect(cohort_client.days_homeless_plus_overrides).to eq(11)
    end
  end

  describe 'sheltered and unsheltered days' do
    before do
      # SO: one day before the effective date, three after
      add_days([effective_date - 20.days] + (effective_date + 10.days..effective_date + 12.days).to_a, project_type: 4, homeless: true, literally_homeless: true)

      cohort.refresh_time_dependant_client_data
      cohort_client.reload
    end

    # The 10 ES days before the effective date
    it 'calculates sheltered days in the last three years as of the effective date' do
      expect(cohort_client.sheltered_days_homeless_last_three_years).to eq(10)
    end

    # The SO day before the effective date
    it 'calculates unsheltered days in the last three years as of the effective date' do
      expect(cohort_client.unsheltered_days_homeless_last_three_years).to eq(1)
    end
  end
end
