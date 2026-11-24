###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReport::Outcomes::OutcomesFilter, type: :model do
  let(:user) { create(:user) }
  let(:filter) { described_class.new(user_id: user.id) }

  [:veteran, :youth, :youth_at_search_start, :youth_at_housed_date].each do |key|
    it "accepts the outcomes report sub-population #{key}" do
      filter.set_from_params({ sub_population: key.to_s })

      expect(filter.sub_population).to eq(key)
    end
  end

  it 'defaults a blank sub-population to all clients' do
    filter.set_from_params({ sub_population: '' })

    expect(filter.sub_population).to eq(:clients)
  end

  it 'rejects an unknown sub-population' do
    expect do
      filter.set_from_params({ sub_population: 'not_a_population' })
    end.to raise_error(AvailableSubPopulations::UnknownSubPopulation)
  end
end
