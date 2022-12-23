###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectSearch
  extend ActiveSupport::Concern
  included do
    def self.text_searcher(text, scope)
      return none unless text.present?

      text.strip!

      query = "%#{text}%"
      scope.where(
        p_t[:ProjectName].matches(query).or(p_t[:ProjectID].matches(query)),
      )
    end
  end
end
