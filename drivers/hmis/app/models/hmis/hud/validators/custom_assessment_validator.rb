###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  # Validate assessment date
  def self.validate_assessment_date(assessment, household_members: nil, options: {})
    date = assessment.assessment_date
    errors = HmisErrors::Errors.new

    # Provide error context, so that they are named according to the FormDefinition item
    item = assessment&.custom_form&.definition&.assessment_date_item
    if item.present?
      options = {
        readable_attribute: item.brief_text || item.text,
        link_id: item.link_id,
        attribute: item.field_name.to_sym,
        **options,
      }
    end

    # Error: date missing
    errors.add :assessment_date, :required, **options unless date.present?
    return errors.errors if errors.any?

    # Error: date in the future
    errors.add :assessment_date, :out_of_range, message: future_message, **options if date.future?
    # Error: > 20 yr ago
    errors.add :assessment_date, :out_of_range, message: over_twenty_years_ago_message, **options if date < (Date.today - 20.years)
    return errors.errors if errors.any?

    enrollment = assessment.enrollment
    entry_date = enrollment&.entry_date
    exit_date = enrollment&.exit_date

    # Error: before entry date
    errors.add :assessment_date, :out_of_range, message: before_entry_message(entry_date), **options if entry_date.present? && entry_date > date && !assessment.intake?
    # Error: after exit date
    errors.add :assessment_date, :out_of_range, message: after_exit_message(exit_date), **options if exit_date.present? && exit_date < date && !assessment.exit?
    # Warning: >30 days ago
    errors.add :assessment_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if date < (Date.today - 30.days)

    # Add Entry Date validations if this is an intake assessment
    errors.push(*Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(assessment.enrollment, household_members: household_members, options: options)) if assessment.intake?

    # Add Exit Date validations if this is an intake assessment
    errors.push(*Hmis::Hud::Validators::ExitValidator.validate_exit_date(assessment.enrollment.exit, household_members: household_members, options: options)) if assessment.exit?

    errors.deduplicate! # Drop any duplicates from entry/exit and default
    errors.errors
  end
end
