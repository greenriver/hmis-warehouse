###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::ExitValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze
  OTHER_DESTINATION = 17

  def configuration
    Hmis::Hud::Exit.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def self.validate_exit_date(exit_date, enrollment:, options:)
    return [] unless exit_date.present?

    errors = HmisErrors::Errors.new

    errors.add :exit_date, :out_of_range, message: future_message, **options if exit_date.future?
    entry_date = enrollment&.entry_date
    errors.add :exit_date, :out_of_range, message: before_entry_message(entry_date), **options if entry_date.present? && entry_date > exit_date
    errors.add :exit_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if exit_date < (Date.today - 30.days)
    errors.errors
  end

  def self.hmis_validate(record, role: nil, **_)
    errors = HmisErrors::Errors.new
    errors.push(*validate_exit_date(record, record.exit_date)) if role == :EXIT
    errors.errors
  end

  def validate(record)
    super(record) do
      record.errors.add :other_destination, :required if record.destination == OTHER_DESTINATION && !record.other_destination.present?
      entry_date = record.enrollment&.entry_date
      record.errors.add :exit_date, :invalid, message: self.class.before_entry_message(entry_date) if entry_date.present? && record.exit_date.present? && entry_date > record.exit_date
    end
  end
end
