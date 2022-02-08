###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class NewLeaseReferral < Select
    attribute :column, String, lazy: true, default: :new_lease_referral
    attribute :translation_key, String, lazy: true, default: 'New Lease Referral'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
