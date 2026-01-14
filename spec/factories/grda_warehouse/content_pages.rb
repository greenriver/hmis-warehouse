###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :content_page, class: 'GrdaWarehouse::ContentPage' do
    sequence(:title) { |n| "Content Page #{n}" }
    sequence(:slug) { |n| "content_page_#{n}" }
    content { 'This is the content of the page.' }

    trait :terms_of_service do
      title { 'Terms of Service' }
      slug { 'terms_of_service' }
      content { 'These are the terms of service for using this application...' }
    end

    trait :privacy_policy do
      title { 'Privacy Policy' }
      slug { 'privacy_policy' }
      content { 'This privacy policy describes how we handle your data...' }
    end
  end
end
