###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ProjectAutoExitConfig < Hmis::ProjectConfig
  validate :length_of_absence_days_ge_30

  def length_of_absence_days=(value)
    self.config_options = { 'length_of_absence_days': value }.to_json
  end

  def length_of_absence_days
    JSON.parse(config_options)['length_of_absence_days']
  end

  def length_of_absence_days_ge_30
    unless config_options
      errors.add(:base, 'config_options must be present')
      return
    end

    begin
      json_blob = JSON.parse(config_options)
    rescue JSON::ParserError
      errors.add(:base, 'config_options must be JSON')
      return
    end

    length_of_absence_days = json_blob['length_of_absence_days']
    unless length_of_absence_days.is_a? Integer
      errors.add(:base, 'config_options must contain an integer length_of_absence_days')
      return
    end

    return unless length_of_absence_days < 30

    errors.add(:base, 'length_of_absence_days must greater than or equal to 30')
  end
end
