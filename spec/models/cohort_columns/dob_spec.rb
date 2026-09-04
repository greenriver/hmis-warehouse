###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::Dob, type: :model do
  let(:user) { create(:user) }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let(:client) { create(:hud_client, DOB: Date.new(1990, 1, 1)) }
  let(:cohort) { create(:cohort) }
  let(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let(:column) { described_class.new(cohort: cohort, cohort_client: cohort_client, current_user: user) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: client.id, source_id: source_client.id, data_source_id: hmis_ds.id, id_in_source: source_client.id.to_s)
  end

  describe '#value' do
    it 'returns the raw dob when the client is not restricted' do
      expect(column.value(cohort_client)).to eq(Date.new(1990, 1, 1))
    end

    it 'returns nil when the client is restricted' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(column.value(cohort_client)).to be_nil
    end
  end
end
