###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_csv_importer_log, class: 'HmisCsvImporter::Importer::ImporterLog' do
    association :data_source, factory: :grda_warehouse_data_source
    status { 'completed' }
    started_at { 1.hour.ago }
    completed_at { Time.current }
    summary { {} }
    phase_metrics { {} }
  end
end
