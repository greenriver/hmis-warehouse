###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
