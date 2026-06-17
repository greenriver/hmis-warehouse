###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :agency_user, class: 'Health::AgencyUser' do
    association :agency, factory: :health_agency
    association :user, factory: :user
  end
end
