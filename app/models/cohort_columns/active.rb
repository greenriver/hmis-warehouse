###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class Active < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :active
    attribute :translation_key, String, lazy: true, default: 'Active'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def has_default_value?
      true
    end

    def default_value client_id
      true
    end
  end
end
