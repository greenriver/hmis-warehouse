# frozen_string_literal: true

FactoryBot.define do
  factory :health_document_export, class: 'Health::DocumentExport' do
    association :user
    type { 'Health::DocumentExports::AgencyPerformanceExport' }
    status { DocumentExportBehavior::COMPLETED_STATUS }
  end
end
