# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::UnitType, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_unit_type) }
  end

  # UnitType has paper_trail and acts_as_paranoid
  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(description: 'Updated') }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
