###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ProjectAutoExitConfig < Hmis::ProjectConfig
  def config_type = 'AUTO_EXIT'

  LENGTH_OF_ABSENCE_DAYS = 'length_of_absence_days'

  validates :config_options, presence: true
  validate :length_of_absence_days_ge_30

  def length_of_absence_days=(value)
    set_config_option(LENGTH_OF_ABSENCE_DAYS, value)
  end

  def length_of_absence_days
    options[LENGTH_OF_ABSENCE_DAYS]
  end

  def length_of_absence_days_ge_30
    return unless options

    length_of_absence_days = options[LENGTH_OF_ABSENCE_DAYS]

    unless length_of_absence_days.is_a? Integer
      errors.add(:base, 'Length of Absence is required')
      return
    end

    return unless length_of_absence_days < 30

    errors.add(:base, 'Length of Absence must be greater than or equal to 30')
  end
end
