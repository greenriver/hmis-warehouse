###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_document_export, class: 'GrdaWarehouse::DocumentExport' do
    association :user
    type { 'ProjectScorecard::DocumentExports::ScorecardExport' } # any valid subclass will do
    status { DocumentExportBehavior::COMPLETED_STATUS }
  end
end
