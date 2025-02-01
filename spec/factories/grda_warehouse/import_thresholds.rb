FactoryBot.define do
  factory :import_threshold, class: 'GrdaWarehouse::ImportThreshold' do
    association :data_source, factory: :source_data_source
    record_count_change_min_threshold { 0 }
    record_count_change_percent_threshold { 0 }
    error_count_min_threshold { 0 }
    error_percent_threshold { 0 }
  end
end
