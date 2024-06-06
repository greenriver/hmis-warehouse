###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO: This validator is no longer used as an ActiveRecord validator, but just holds the date validator function
# that's called when the assessment form is submitted. It could be refactored to reduce confusion
class Hmis::Hud::Validators::CustomAssessmentValidator < Hmis::Hud::Validators::BaseValidator
  def self.already_has_annual_full_message(date)
    "Client already has an annual assessment on the same date (#{date.strftime('%m/%d/%Y')})"
  end

  def self.already_has_update_full_message(date)
    "Client already has an update assessment on the same date (#{date.strftime('%m/%d/%Y')})"
  end

  # Note that this function is NOT called when we call `.valid?` on an assessment.
  # `.valid?` checks whether the *record* is valid, but this function checks validity from the perspective of the
  # assessment at the moment when it's submitted by the HMIS
  def self.validate_assessment_date(assessment, household_members: nil, options: {})
    date = assessment.assessment_date
    errors = HmisErrors::Errors.new

    # Provide error context, so that they are named according to the FormDefinition item
    item = assessment&.definition&.assessment_date_item
    if item.present?
      options = {
        readable_attribute: item.brief_text || item.text,
        link_id: item.link_id,
        attribute: item.mapping&.field_name&.to_sym,
        **options,
      }
    end

    # Error: date missing
    errors.add :assessment_date, :required, **options unless date.present?
    return errors.errors if errors.any?

    # Error: date in the future
    errors.add :assessment_date, :out_of_range, message: future_message, **options if date.future?
    # Error: > 20 yr ago
    errors.add :assessment_date, :out_of_range, message: over_twenty_years_ago_message, **options if date < (Date.current - 20.years)
    return errors.errors if errors.any?

    enrollment = assessment.enrollment
    entry_date = enrollment&.entry_date
    exit_date = enrollment&.exit_date

    # Error: before entry date
    errors.add :assessment_date, :out_of_range, message: before_entry_message(entry_date), **options if entry_date.present? && entry_date > date && !assessment.intake?
    # Error: after exit date
    errors.add(:assessment_date, :out_of_range, message: after_exit_message(exit_date), **options) if
      exit_date.present? && exit_date < date && (assessment.intake? || assessment.annual? || assessment.update?)

    # Warning: >30 days ago
    errors.add :assessment_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if date < (Date.current - 30.days)

    # Add Entry Date validations if this is an intake assessment
    errors.push(*Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollment, household_members: household_members, options: options)) if assessment.intake?

    # Add Exit Date validations if this is an exit assessment
    if assessment.exit?
      exit = enrollment.exit
      exit.exit_date = assessment.assessment_date if exit
      errors.push(*Hmis::Hud::Validators::ExitValidator.validate_exit_date(exit, household_members: household_members, options: options))
    end

    # HUD Annual/Update assessment date validations
    if assessment.annual?
      other_annual_dates = enrollment.annual_assessments.where.not(id: assessment.id).pluck(:assessment_date)
      # Warning: shouldn't have 2 annuals on the same day.
      # This could probably be an error, but, the user doesn't necessarily have access to delete the dup. Can make it a hard stop later if desired.
      errors.add :assessment_date, :invalid, severity: :warning, full_message: already_has_annual_full_message(date), **options if other_annual_dates.include?(date)
      # TODO: warn if annual is close to another annual?
      # TODO: warn about relationship to other annuals dates?

    elsif assessment.update?
      other_update_dates = enrollment.update_assessments.where.not(id: assessment.id).pluck(:assessment_date)
      # Warning: shouldn't have 2 updates on the same day
      errors.add :assessment_date, :invalid, severity: :warning, full_message: already_has_update_full_message(date), **options if other_update_dates.include?(date)
    end

    errors.deduplicate! # Drop any duplicates from entry/exit and default
    errors.errors
  end
end
