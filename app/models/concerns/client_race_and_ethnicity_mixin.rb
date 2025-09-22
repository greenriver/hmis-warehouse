# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientRaceAndEthnicityMixin
  extend ActiveSupport::Concern
  included do
    scope :race_ethnicity_alternative, ->(key, hispanic_latinaeo = false) {
      race_selection = { race: key.to_sym, hispanic: hispanic_latinaeo }
      builder = RaceEthnicityQueryBuilder.new([race_selection])
      builder.apply_to_scope(self, c_t)
    }

    scope :multi_racial_clients, ->(include_hispanic_latinaeo: false) {
      race_selection = { race: :multi_racial, hispanic: include_hispanic_latinaeo }
      builder = RaceEthnicityQueryBuilder.new([race_selection])
      builder.apply_to_scope(self, c_t)
    }
  end
end
