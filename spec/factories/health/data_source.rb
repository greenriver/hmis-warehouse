###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :health_ds_1, class: 'Health::DataSource' do
    name { 'BHCHP EPIC' }
  end

  factory :referral_ds, class: 'Health::DataSource' do
    name { 'Patient Referral' }
  end
end
