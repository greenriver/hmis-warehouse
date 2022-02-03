###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class RelatedUsers < ReadOnly
    attribute :column, String, lazy: true, default: :related_users
    attribute :translation_key, String, lazy: true, default: 'Related Users'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      cohort_client.related_users
    end
  end
end
