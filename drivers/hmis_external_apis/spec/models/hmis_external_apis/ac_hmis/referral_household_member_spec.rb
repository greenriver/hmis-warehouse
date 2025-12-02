# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../../hmis/spec/support/shared_examples/versioning_and_paranoia'

RSpec.describe HmisExternalApis::AcHmis::ReferralHouseholdMember, type: :model do
  it_behaves_like 'versioned model' do
    let(:build_record) do
      -> { create(:hmis_external_api_ac_hmis_referral_household_member) }
    end

    let(:update_attributes_for_versioning) do
      ->(record) { record.update!(relationship_to_hoh: 'child') }
    end
  end

  describe 'version metadata' do
    include_context 'with paper trail'

    it 'stores client_id in version metadata' do
      member = create(:hmis_external_api_ac_hmis_referral_household_member)

      version = member.versions.last
      expect(version.client_id).to eq(member.client.id)
    end
  end
end
