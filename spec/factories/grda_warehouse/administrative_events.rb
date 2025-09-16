###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_administrative_event, class: 'GrdaWarehouse::AdministrativeEvent' do
    user
    date { '2018-05-30' }
    title { 'Title' }
    description { 'Description' }
  end
end
