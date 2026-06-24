###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_import_log, class: 'GrdaWarehouse::ImportLog' do
    association :data_source, factory: :grda_warehouse_data_source
    files { [['HmisCsvTwentyTwentyFour::Loader::Enrollment', 'Enrollment.csv']] }
    summary { 'Test import' }
    completed_at { Time.current }
    type { 'GrdaWarehouse::ImportLog' }
  end
end
