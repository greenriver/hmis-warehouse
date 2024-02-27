###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ProjectAutoExitConfig < Hmis::ProjectConfig
  validates :config_options, presence: true
  validate :length_of_absence_days_ge_30

  def length_of_absence_days=(value)
    self.config_options = { 'length_of_absence_days': value }.to_json
  end

  def length_of_absence_days
    JSON.parse(config_options)['length_of_absence_days']
  end

  def length_of_absence_days_ge_30
    return unless config_options

    length_of_absence_days = options['length_of_absence_days']

    unless length_of_absence_days.is_a? Integer
      errors.add(:base, 'config_options must contain an integer length_of_absence_days')
      return
    end

    return unless length_of_absence_days < 30

    errors.add(:base, 'length_of_absence_days must be greater than or equal to 30')
  end
end
