class Hmis::Hud::Validators::CustomAssessmentValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
    # CE fields are not present on the custom assessment
    :AssessmentID,
    :AssessmentLocation,
    :AssessmentType,
    :AssessmentLevel,
    :PrioritizationStatus,
  ].freeze

  def configuration
    Hmis::Hud::CustomAssessment.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def self.validate_assessment_date(date, enrollment:, options:)
    return [] unless date.present?

    errors = HmisErrors::Errors.new

    # error: date in the future
    errors.add :assessment_date, :out_of_range, message: future_message, **options if date.future?
    # error: >20yr ogo
    errors.add :assessment_date, :out_of_range, message: over_twenty_years_ago_message, **options if date < (Date.today - 20.years)

    entry_date = enrollment&.entry_date
    exit_date = enrollment&.exit_date
    # error: before entry date
    errors.add :assessment_date, :out_of_range, message: before_entry_message(entry_date), **options if entry_date.present? && entry_date > date
    # error: after exit date
    errors.add :assessment_date, :out_of_range, message: after_exit_message(exit_date), **options if exit_date.present? && exit_date < date
    # warning: >30 days ago
    errors.add :assessment_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if date < (Date.today - 30.days)

    errors.errors
  end
end
