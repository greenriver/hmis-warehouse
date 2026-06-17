###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :provider, class: 'Health::Team::Provider' do
    first_name { 'Dr' }
    last_name { 'Doctor' }
    email { 'provider@openpath.biz' }
    organization { 'OpenPath' }
  end
end
