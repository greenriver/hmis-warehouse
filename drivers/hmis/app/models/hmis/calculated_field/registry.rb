# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::CalculatedField
  # Maps Dentaku variable names to resolver classes. Resolvers are off by default;
  # enable via AppConfigProperty key `calculated_fields/resolvers/<name>`.
  module Registry
    RESOLVERS = {
      hopwa_weeks_of_service: 'Hmis::CalculatedField::Resolvers::HopwaWeeksOfService',
      enrollments_count: 'Hmis::CalculatedField::Resolvers::EnrollmentsCount',
    }.freeze

    def self.enabled
      enabled_keys = AppConfigProperty.
        where(key: RESOLVERS.keys.map { |k| "calculated_fields/resolvers/#{k}" }).
        where(value: true).
        pluck(:key).
        to_set

      RESOLVERS.filter_map do |var_name, class_name|
        next unless enabled_keys.include?("calculated_fields/resolvers/#{var_name}")

        [var_name, class_name.constantize]
      end.to_h
    end
  end
end
