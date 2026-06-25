###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :signable_careplan, class: 'Health::SignableDocument' do
    user_id { 1 }
    signable_type { Health::Careplan }
    signers { [{ email: 'patient@openpath.biz' }, { email: 'provider@openpath.biz' }] }
    signature_request { create :signature_request }
  end
end
