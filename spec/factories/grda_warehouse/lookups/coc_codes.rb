###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :lookup_coc, class: 'GrdaWarehouse::Lookups::CocCode' do
    # these are required by db schema
    active { true }
    official_name { 'Fake CoC 500' }
    coc_code { 'XX-500' }
  end
end
