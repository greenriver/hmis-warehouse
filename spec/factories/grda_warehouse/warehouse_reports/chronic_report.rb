# frozen_string_literal: true

FactoryBot.define do
  factory :chronic_report, class: 'GrdaWarehouse::WarehouseReports::ChronicReport' do
    parameters { {} }
    data { [] }
  end
end
