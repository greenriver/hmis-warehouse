# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::Ce::Referral, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_ce_referral, data_source: ds1) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(referral_origin: Hmis::Ce::Referral::DIRECT_SEND_ORIGIN) }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
