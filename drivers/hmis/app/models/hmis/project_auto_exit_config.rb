###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ProjectAutoExitConfig < Hmis::ProjectConfig
  validates :config_options, presence: true
  validate :length_of_absence_days_ge_30

  def config_type = 'AUTO_EXIT'

  def length_of_absence_days=(value)
    new_options = { 'length_of_absence_days': value }.stringify_keys
    merged_options = options ? options.merge(new_options) : new_options
    self.config_options = merged_options.to_json
  end

  def length_of_absence_days
    options['length_of_absence_days']
  end

  def length_of_absence_days_ge_30
    return unless options

    length_of_absence_days = options['length_of_absence_days']

    unless length_of_absence_days.is_a? Integer
      errors.add(:base, 'Length of Absence is required')
      return
    end

    return unless length_of_absence_days < 30

    errors.add(:base, 'Length of Absence must be greater than or equal to 30')
  end
end
