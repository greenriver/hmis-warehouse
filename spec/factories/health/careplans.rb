###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :careplan, class: 'Health::Careplan' do
    provider_id { 1 }
    provider_signature_mode { :email }
  end

  factory :pctp_careplan, class: 'Health::PctpCareplan' do
    transient do
      patient { create(:patient) }
    end
    patient_id { patient.id }
    instrument { create(:careplan, patient: patient) }
  end
end
