###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :import_override, class: 'HmisCsvImporter::ImportOverride' do
    last_used_on { 3.months.ago }
  end
end
