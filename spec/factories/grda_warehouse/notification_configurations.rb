FactoryBot.define do
  factory :notification_configuration_import_threshold, class: 'GrdaWarehouse::NotificationConfiguration' do
    association :source, factory: :import_threshold

    trait :error_count_notification_event do
      notification_slug { 'error_threshold_exceeded' }
    end

    trait :record_count_change_notification_event do
      notification_slug { 'count_threshold_exceeded' }
    end
  end
end
