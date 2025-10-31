# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../../hmis/spec/support/shared_examples/versioning_and_paranoia'

RSpec.describe HmisExternalApis::AcHmis::Referral, type: :model do
  let(:enrollment) { create(:hmis_hud_enrollment) }

  it_behaves_like 'versioned model' do
    let(:build_record) do
      -> { create(:hmis_external_api_ac_hmis_referral, enrollment: enrollment) }
    end

    let(:update_attributes_for_versioning) do
      ->(record) { record.update!(referral_notes: 'Updated notes') }
    end
  end

  describe 'version metadata' do
    include_context 'with paper trail'

    it 'stores enrollment_id, client_id, and project_id in version metadata' do
      referral = create(:hmis_external_api_ac_hmis_referral, enrollment: enrollment)

      version = referral.versions.last
      expect(version.enrollment_id).to eq(enrollment.id)
      expect(version.client_id).to eq(enrollment.client.id)
      expect(version.project_id).to eq(enrollment.project.id)
    end
  end
end
