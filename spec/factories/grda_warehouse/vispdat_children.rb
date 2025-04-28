###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_vispdat_child, class: 'GrdaWarehouse::Vispdat::Child' do
    first_name { 'MyString' }
    last_name { 'MyString' }
    dob { '2017-11-29' }
    family { nil }
  end
end
