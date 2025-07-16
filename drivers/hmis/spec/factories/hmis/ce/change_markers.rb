# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_change_marker, class: 'Hmis::Ce::ChangeMarker' do
    association :trackable, factory: :fixed_destination_client
    current_version { 1 }
    processed_version { 0 }
  end
end
