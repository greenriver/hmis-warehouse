###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::EnrollmentValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
    :ProjectID, # allowed to be null if wip record is present
  ].freeze

  def configuration
    Hmis::Hud::Enrollment.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def self.validate_entry_date(entry_date, enrollment:, options: {})
    return [] unless entry_date.present?

    errors = HmisErrors::Errors.new
    dob = enrollment.client&.dob
    exit_date = enrollment&.exit_date

    errors.add :entry_date, :out_of_range, message: future_message, **options if entry_date.future?
    errors.add :entry_date, :out_of_range, message: over_twenty_years_ago_message, **options if entry_date < (Date.today - 20.years)
    errors.add :entry_date, :out_of_range, message: before_dob_message, **options if dob.present? && dob > entry_date
    errors.add :entry_date, :out_of_range, message: after_exit_message(exit_date), **options if exit_date.present? && exit_date < entry_date

    unless enrollment.head_of_household?
      hoh_entry_date = enrollment.hoh_entry_date
      errors.add :entry_date, :out_of_range, severity: :warning, message: before_hoh_entry_message(hoh_entry_date), **options if hoh_entry_date.present? && entry_date < hoh_entry_date
    end

    errors.add :entry_date, :information, severity: :warning, message: equals_dob_message, **options if dob.present? && dob == entry_date
    errors.add :entry_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if entry_date < (Date.today - 30.days)

    errors.errors
  end

  def self.hmis_validate(record, role: nil, **_)
    errors = HmisErrors::Errors.new
    errors.push(*validate_entry_date(record, record.entry_date)) if role == :INTAKE
    errors.errors
  end

  def validate(record)
    super(record) do
      record.errors.add :project_id, :required if record.project_id.nil? && record.wip.nil?
    end
  end
end
