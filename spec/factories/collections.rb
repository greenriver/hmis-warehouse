###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    sequence(:name) { |n| "Collection #{n}" }
    collection_type { 'Projects' }
  end
end
