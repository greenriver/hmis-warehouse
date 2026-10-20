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

  def add_days(dates, project_type:, homeless:, literally_homeless:)
    she = create(:she_entry, client: client, project_type: project_type)
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
end
