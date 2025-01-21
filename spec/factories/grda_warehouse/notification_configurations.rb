FactoryBot.define do
  factory :notification_configuration_import_threshold, class: 'GrdaWarehouse::NotificationConfiguration' do
    association :source, factory: :import_threshold

    trait :import_error_count_slug do
      notification_slug { 'NotificationTypes::ImportErrorCountThreshold' }
    end

    trait :import_record_count_change_slug do
      notification_slug { 'NotificationTypes::ImportRecordCountChangeThreshold' }
    end
  end
end
