###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :import_override, class: 'HmisCsvImporter::ImportOverride' do
    last_used_on { 3.months.ago }
  end
end
