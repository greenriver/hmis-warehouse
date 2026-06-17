###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :health_document_export, class: 'Health::DocumentExport' do
    association :user
    type { 'Health::DocumentExports::AgencyPerformanceExport' } # any valid subclass will do
    status { DocumentExportBehavior::COMPLETED_STATUS }
  end
end
