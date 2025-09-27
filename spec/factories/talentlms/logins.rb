# frozen_string_literal: true

FactoryBot.define do
  factory :talentlms_login, class: 'Talentlms::Login' do
    lms_user_id { 1 }
  end
end
