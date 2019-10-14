###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class Chronic < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :chronic
    attribute :translation_key, String, lazy: true, default: 'On Previous Chronic List'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Manually entered record of previous chronic membership'
    end
  end
end
