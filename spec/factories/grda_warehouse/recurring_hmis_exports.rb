# frozen_string_literal: true

FactoryBot.define do
  factory :recurring_hmis_export, class: 'GrdaWarehouse::RecurringHmisExport' do
    association :user
    every_n_days { 7 }
    reporting_range { 'fixed' }
    reporting_range_days { 0 }
    options do
      {
        start_date: 2.weeks.ago.to_date.iso8601,
        end_date: 1.week.ago.to_date.iso8601,
        version: '2024',
        project_ids: [],
      }
    end
    s3_region { nil }
    s3_bucket { nil }

    trait :with_history do
      after(:create) do |recurring_export|
        create(:recurring_hmis_export_link, recurring_hmis_export: recurring_export, exported_at: 10.days.ago.to_date)
      end
    end

    trait :with_s3_settings do
      s3_region { 'us-east-1' }
      s3_bucket { 'test-bucket' }
    end

    trait :with_zip_encryption do
      zip_password { 'secret123' }
      encryption_type { 'zip' }
    end
  end
end
