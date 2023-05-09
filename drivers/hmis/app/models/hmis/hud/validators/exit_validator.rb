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

  def self.hoh_exits_before_others
    "is before other household member's exit date"
  end

  def self.member_exits_after_hoh(hoh_exit_date)
    "is after the Head of Household's exit date (#{hoh_exit_date.strftime('%m/%d/%Y')})"
  end

  def self.validate_exit_date(exit, household_members: nil, options: {})
    exit_date = exit&.exit_date
    return [] unless exit_date.present?

    errors = HmisErrors::Errors.new

    errors.add :exit_date, :out_of_range, message: future_message, **options if exit_date.future?

    enrollment = exit.enrollment
    entry_date = enrollment.entry_date
    dob = enrollment.client&.dob
    household_members ||= enrollment.household_members

    errors.add :exit_date, :out_of_range, message: before_entry_message(entry_date), **options if entry_date.present? && entry_date > exit_date
    errors.add :exit_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if exit_date < (Date.today - 30.days)
    errors.add :exit_date, :out_of_range, message: before_dob_message, **options if dob.present? && dob > exit_date
    return errors.errors if errors.any?

    if household_members.size > 1
      member_exit_dates ||= household_members.map(&:exit_date).compact

      # If HoH, other members exit dates shouldn't be later
      errors.add :exit_date, :out_of_range, severity: :warning, message: hoh_exits_before_others if enrollment.head_of_household? && member_exit_dates.any? { |date| date > exit_date }

      # If non-HoH, shouldn't be after HoH member
      hoh_exit_date = household_members.find(&:head_of_household?)&.exit_date unless enrollment.head_of_household?
      errors.add :exit_date, :out_of_range, severity: :warning, message: member_exits_after_hoh(hoh_exit_date) if hoh_exit_date && exit_date > hoh_exit_date
    end

    errors.errors
  end

  def self.hmis_validate(record, role: nil, **_)
    errors = HmisErrors::Errors.new
    errors.push(*validate_exit_date(record)) if role == :EXIT
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
