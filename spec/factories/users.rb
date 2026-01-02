###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { 'Green' }
    last_name { 'River' }
    sequence(:email) { |n| "user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }

    trait :subscribed_to_vispdat_completed do
      after(:create) do |user|
        alert_def = GrdaWarehouse::AlertDefinition.find_or_create_by!(
          code: 'vispdat_completed',
        ) do |ad|
          ad.name = 'VI-SPDAT Completed'
          ad.category = 'client_activity'
          ad.active = true
        end
        contact = user.system_contact!
        contact.contact_alert_subscriptions.find_or_create_by!(
          alert_definition: alert_def,
        )
      end
    end

    trait :subscribed_to_client_added do
      after(:create) do |user|
        alert_def = GrdaWarehouse::AlertDefinition.find_or_create_by!(
          code: 'client_added',
        ) do |ad|
          ad.name = 'Client Added'
          ad.category = 'client_activity'
          ad.active = true
        end
        contact = user.system_contact!
        contact.contact_alert_subscriptions.find_or_create_by!(
          alert_definition: alert_def,
        )
      end
    end

    trait :subscribed_to_anomaly_identified do
      after(:create) do |user|
        alert_def = GrdaWarehouse::AlertDefinition.find_or_create_by!(
          code: 'anomaly_identified',
        ) do |ad|
          ad.name = 'Anomaly Identified'
          ad.category = 'data_quality'
          ad.active = true
        end
        contact = user.system_contact!
        contact.contact_alert_subscriptions.find_or_create_by!(
          alert_definition: alert_def,
        )
      end
    end
  end

  factory :acl_user, class: 'User' do
    first_name { 'Green' }
    last_name { 'River' }
    sequence(:email) { |n| "acl_user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }
    permission_context { 'acls' }
  end

  factory :user_2fa, class: 'User' do
    first_name { 'Green2fa' }
    last_name { 'River' }
    sequence(:email) { |n| "user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }
    # Maintained for backward compatibility with legacy 2FA until we're comfortable with the state of Oauth2-proxy
    otp_secret { User.generate_otp_secret }
  end
end
