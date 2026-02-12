# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::Ce::ReferralDeclineReason, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:ce_referral_decline_reason, data_source: ds1) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(name: "Updated #{record.name}") }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end

  describe 'scopes' do
    describe '.viewable_by' do
      let(:user) { create(:hmis_user, data_source: ds1) }
      let!(:ds2) { create(:hmis_data_source) }
      let!(:reason_ds1) { create(:ce_referral_decline_reason, data_source: ds1) }
      let!(:reason_ds2) { create(:ce_referral_decline_reason, data_source: ds2) }

      it 'returns reasons for the user\'s data source' do
        expect(described_class.viewable_by(user)).to include(reason_ds1)
        expect(described_class.viewable_by(user)).not_to include(reason_ds2)
      end
    end
  end
end
