# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::UnitOccupancy, type: :model do
  include_context 'hmis base setup'
  let(:unit2) { create :hmis_unit }

  let(:build_record) do
    -> { create(:hmis_unit_occupancy) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(unit_id: unit2.id) }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
