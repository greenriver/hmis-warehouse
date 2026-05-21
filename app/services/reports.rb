###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reports
  # Get the archival grace period in days from AppConfigProperty, defaulting to 60
  def self.archival_grace_period_days
    property = AppConfigProperty.find_by(key: 'reports/archival_grace_period_days')
    return 60 if property.nil?

    value = property.value
    # AppConfigProperty stores values as JSON, so numbers are already parsed
    # Handle both numeric values and string representations
    value.to_i
  end
end
