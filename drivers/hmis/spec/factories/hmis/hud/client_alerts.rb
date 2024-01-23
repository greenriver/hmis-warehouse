###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

FactoryBot.define do
  # clients must share a base class to prevent PersonalID Sequence collision
  factory :hmis_client_alert, class: 'Hmis::ClientAlert' do
    created_by { association :hmis_hud_user }
    client { association :hmis_hud_client }
    note { 'Something wacky has happened' }
    created_at { Time.current }
    updated_at { Time.current }
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
