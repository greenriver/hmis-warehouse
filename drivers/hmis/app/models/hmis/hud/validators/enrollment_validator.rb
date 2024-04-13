###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::EnrollmentValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
    :EnrollmentCoC,
    :ProjectID, # allowed to be null if wip record is present
    :LastPermanentZIP,
  ].freeze

  def configuration
    Hmis::Hud::Enrollment.hmis_configuration(version: '2024').except(*IGNORED)
  end

  def self.one_hoh_full_message
    'Household already has a Head of Household. Please select a different relationship to HoH.'
  end

  def self.first_member_hoh_full_message
    'The first household member must be the HoH. The HoH can be changed at a later step.'
  end

  def self.duplicate_member_full_message
    'Client is already a member of this household.'
  end

  def self.already_enrolled_full_message
    'Client has another enrollment in this project that conflicts with this entry date.'
  end

  def self.find_conflict_severity(enrollment)
    conflict_scope = Hmis::Hud::Enrollment.
      where(personal_id: enrollment.personal_id, data_source_id: enrollment.data_source_id).
      with_conflicting_dates(project: enrollment.project, range: enrollment.entry_date...enrollment.exit_date)

    if enrollment.persisted?
      # If the entry date is being changed on an EXISTING enrollment, and it overlaps with another one, it should be a warning
      conflict_scope = conflict_scope.where.not(id: enrollment.id)
      return :warning if conflict_scope.any?
    else
      min_conflict_date = conflict_scope.minimum(:entry_date)
      if min_conflict_date
        # If the entry date is being set on a NEW enrollment, and the entry date is on or after the entry date of any conflicting enrollments, it should be an error.
        return :error if enrollment.entry_date >= min_conflict_date

        # if the entry date is being set on a NEW enrollment, and the entry date is before the entry date of any conflicting enrollments, it should be a warning
        return :warning if enrollment.entry_date < min_conflict_date
      end
    end
  end

  def self.validate_entry_date(enrollment, household_members: nil, options: {})
    entry_date = enrollment&.entry_date
    return [] unless entry_date.present?

    errors = HmisErrors::Errors.new
    dob = enrollment.client&.dob
    exit_date = enrollment.exit_date

    errors.add :entry_date, :out_of_range, message: future_message, **options if entry_date.future?
    errors.add :entry_date, :out_of_range, message: over_twenty_years_ago_message, **options if entry_date < (Date.current - 20.years)
    errors.add :entry_date, :out_of_range, message: before_dob_message, **options if dob.present? && dob > entry_date
    errors.add :entry_date, :out_of_range, message: after_exit_message(exit_date), **options if exit_date.present? && exit_date < entry_date
    return errors.errors if errors.any?

    conflict_severity = find_conflict_severity(enrollment)
    errors.add(:entry_date, :out_of_range, severity: conflict_severity, full_message: already_enrolled_full_message) if conflict_severity

    unless enrollment.head_of_household?
      household_members ||= enrollment.household_members
      hoh_entry_date = household_members.find(&:head_of_household?)&.entry_date
      errors.add :entry_date, :out_of_range, severity: :warning, message: before_hoh_entry_message(hoh_entry_date), **options if hoh_entry_date.present? && entry_date < hoh_entry_date
    end

    errors.add :entry_date, :information, severity: :warning, message: equals_dob_message, **options if dob.present? && dob == entry_date
    errors.add :entry_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if entry_date < (Date.current - 30.days)

    errors.errors
  end

  def self.hmis_validate(record, role: nil, **_)
    errors = HmisErrors::Errors.new
    errors.push(*validate_entry_date(record)) if [:INTAKE, :ENROLLMENT].include?(role&.to_sym)

    if record.new_record?
      household_members = record.household_members
      is_hoh = record.head_of_household?
      has_hoh = household_members.any?(&:head_of_household?)
      # Error: client is already a member of this household
      already_enrolled = household_members.open_on_date.where(personal_id: record.personal_id).exists?
      errors.add :base, :invalid, full_message: duplicate_member_full_message if already_enrolled
      return errors.errors if already_enrolled

      # Error: adding second HoH to existing hh
      errors.add :relationship_to_hoh, :invalid, full_message: one_hoh_full_message if is_hoh && has_hoh
      # Error: creating new hh without HoH
      errors.add :relationship_to_hoh, :invalid, full_message: first_member_hoh_full_message if !is_hoh && !has_hoh && household_members.empty?
      # Error: adding non-HoH member to hh that lacks HoH
      errors.add :relationship_to_hoh, :invalid, full_message: one_hoh_full_message if !is_hoh && !has_hoh && household_members.exists?
    end

    errors.errors
  end

  def validate(record)
    super(record) do
      # enrollment.project_id should match the project.project_id. The rails association is through actual_project_id
      if record.project
        record.errors.add :project_id, 'reference does not match DB PK' if record.ProjectID && record.ProjectID != record.project.ProjectID
        record.errors.add :project_id, 'must match enrollment data source' if record.project.data_source_id != record.data_source_id
      else
        record.errors.add :project_id, 'must be present' unless record.project
      end
    end
  end
end
