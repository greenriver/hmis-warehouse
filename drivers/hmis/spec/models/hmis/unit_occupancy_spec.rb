# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::UnitOccupancy, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_unit_occupancy) }
  end

  # UnitOccupancy does not have paper_trail in the model; only paranoia
  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end
end
