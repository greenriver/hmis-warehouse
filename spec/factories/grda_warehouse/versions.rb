# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_version, class: 'GrdaWarehouse::Version' do
    item_type { 'GrdaWarehouse::ContactAlertSubscription' }
    item_id { 1 }
    event { 'update' }
    object_changes do
      {
        'updated_at' => [1.day.ago, Time.current],
      }.to_yaml
    end
  end
end
