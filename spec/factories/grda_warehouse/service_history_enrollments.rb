FactoryBot.define do
  factory :she_entry, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    record_type { :entry }
  end
  factory :she_exit, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    record_type { :exit }
  end
  factory :she_first, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    record_type { :first }
  end
end
