# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::DateAddedToCohort, type: :model do
  let(:user) { create :user }
  let(:client) { create :hud_client }
  let(:cohort) { create :cohort }
  # Setup required cohort column types for cohort tabs
  let(:date_added_to_cohort_column_type) { create(:cohort_column_type, class_name: 'CohortColumns::DateAddedToCohort') }
  let(:date_added_to_cohort) { build :date_added_to_cohort, cohort: cohort, cohort_column_type: :date_added_to_cohort_column_type }

  before(:all) do
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
  end

  it 'Sets the date added to the cohort client' do
    AddCohortClientsJob.new.perform(cohort.id, client.id.to_s, user.id)
    expect(cohort.cohort_clients.count).to eq(1)
    cohort_client = cohort.cohort_clients.first
    expect(cohort_client.date_added_to_cohort).to eq(Date.current)
  end

  it 'Resets the date added to the cohort client when is is removed and re-added' do
    # Add client yesterday
    Timecop.travel(Date.yesterday)
    AddCohortClientsJob.new.perform(cohort.id, client.id.to_s, user.id)
    expect(cohort.cohort_clients.count).to eq(1)
    cohort_client = cohort.cohort_clients.first
    expect(cohort_client.cohort_client_changes.count).to eq(1) # Newly created
    expect(cohort_client.date_added_to_cohort).to eq(Date.current)
    Timecop.return

    # Remove client
    cohort_client.destroy
    expect(cohort.cohort_clients.count).to eq(0)

    # Re-add
    AddCohortClientsJob.new.perform(cohort.id, client.id.to_s, user.id)
    expect(cohort.cohort_clients.count).to eq(1)
    cohort_client = cohort.cohort_clients.first
    expect(cohort_client.cohort_client_changes.count).to be > 1 # We re-added the same client
    expect(cohort_client.date_added_to_cohort).to eq(Date.current)
  end
end
