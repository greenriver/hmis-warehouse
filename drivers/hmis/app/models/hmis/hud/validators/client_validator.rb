###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::ClientValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :Gender,
    :Race,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Client.hmis_configuration(version: '2024').except(*IGNORED)
  end

  def self.first_or_last_required_full_message
    'First or Last name is required'
  end

  def self.too_old_dob_message
    'cannot be more than 120 years ago'
  end

  def validate(record)
    super(record) do
      record.errors.add :gender, :required if !skipped_attributes(record).include?(:gender) && ::HudUtility2024.gender_id_to_field_name.except(8, 9, 99).values.any? { |field| record.send(field).nil? }
      record.errors.add :race, :required if !skipped_attributes(record).include?(:race) && ::HudUtility2024.races.except('RaceNone').keys.any? { |field| record.send(field).nil? }

      if record.dob.present?
        record.errors.add :dob, :out_of_range, message: self.class.future_message if record.dob.future?
        record.errors.add :dob, :out_of_range, message: self.class.too_old_dob_message if record.dob < (Date.current - 120.years)
      end

      # First or Last exists
      record.errors.add(:first_name, :invalid, full_message: self.class.first_or_last_required_full_message) unless record.first_name.present? || record.last_name.present?

      # Exactly 1 primary name
      if record.names.any?
        primary_names = record.names.reject(&:marked_for_destruction?).select(&:primary?)
        record.errors.add :names, :invalid, full_message: 'One primary name is required' if primary_names.size != 1
      end
    end
  end
end
