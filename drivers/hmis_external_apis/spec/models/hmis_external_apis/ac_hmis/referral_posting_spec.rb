# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../../hmis/spec/support/shared_examples/versioning_and_paranoia'

RSpec.describe HmisExternalApis::AcHmis::ReferralPosting, type: :model do
  it_behaves_like 'versioned model' do
    let(:build_record) do
      -> { create(:hmis_external_api_ac_hmis_referral_posting) }
    end

    let(:update_attributes_for_versioning) do
      ->(record) { record.update!(status: 'accepted_pending_status') }
    end
  end

  describe 'version metadata' do
    include_context 'with paper trail'

    it 'stores project_id in version metadata' do
      posting = create(:hmis_external_api_ac_hmis_referral_posting)

      version = posting.versions.last
      expect(version.project_id).to eq(posting.project.id)
    end
  end
end
