###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :available_file_tag, class: 'GrdaWarehouse::AvailableFileTag' do
    name { 'Tag' }
    group { 'Group' }
    included_info { 'This is included' }
  end

  factory :grda_warehouse_available_file_tag, class: 'GrdaWarehouse::AvailableFileTag' do
    name { 'MyString' }
    group { 'MyString' }
    weight { 1 }
  end

  factory :coc_roi_tag, class: 'GrdaWarehouse::AvailableFileTag' do
    name { 'HAN Release' }
    group { 'Consent Forms' }
    weight { 1 }
    consent_form { true }
    full_release { true }
    requires_effective_date { true }
    coc_available { true }
  end
end
