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
    'Client is already enrolled in this project.'
  end

  def self.validate_entry_date(enrollment, household_members: nil, options: {})
    entry_date = enrollment.entry_date
    return [] unless entry_date.present?

    errors = HmisErrors::Errors.new
    dob = enrollment.client&.dob
    exit_date = enrollment&.exit_date

    errors.add :entry_date, :out_of_range, message: future_message, **options if entry_date.future?
    errors.add :entry_date, :out_of_range, message: over_twenty_years_ago_message, **options if entry_date < (Date.today - 20.years)
    errors.add :entry_date, :out_of_range, message: before_dob_message, **options if dob.present? && dob > entry_date
    errors.add :entry_date, :out_of_range, message: after_exit_message(exit_date), **options if exit_date.present? && exit_date < entry_date
    return errors.errors if errors.any?

    unless enrollment.head_of_household?
      household_members ||= enrollment.household_members
      hoh_entry_date = household_members.find(&:head_of_household?)&.entry_date
      errors.add :entry_date, :out_of_range, severity: :warning, message: before_hoh_entry_message(hoh_entry_date), **options if hoh_entry_date.present? && entry_date < hoh_entry_date
    end

    errors.add :entry_date, :information, severity: :warning, message: equals_dob_message, **options if dob.present? && dob == entry_date
    errors.add :entry_date, :information, severity: :warning, message: over_thirty_days_ago_message, **options if entry_date < (Date.today - 30.days)

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
      already_in_household = household_members.where(personal_id: record.personal_id).exists?
      errors.add :base, :invalid, full_message: duplicate_member_full_message if already_in_household
      return errors.errors if already_in_household

      # Error: adding second HoH to existing hh
      errors.add :relationship_to_hoh, :invalid, full_message: one_hoh_full_message if is_hoh && has_hoh
      # Error: creating new hh without HoH
      errors.add :relationship_to_hoh, :invalid, full_message: first_member_hoh_full_message if !is_hoh && !has_hoh && household_members.empty?
      # Error: adding non-HoH member to hh that lacks HoH
      errors.add :relationship_to_hoh, :invalid, full_message: one_hoh_full_message if !is_hoh && !has_hoh && household_members.exists?

      # Warning: client is already enrolled in this project
      # NOTE: only warns if there are eixisting active enrollments, not WIP enrollments
      already_enrolled = record.entry_date.present? && Hmis::Hud::Enrollment.where(**record.slice(:project_id, :personal_id, :data_source_id)).open_on_date(record.entry_date).exists?
      errors.add :base, :information, severity: :warning, full_message: already_enrolled_full_message if already_enrolled
    end

    errors.errors
  end

  def validate(record)
    super(record) do
      record.errors.add :project_id, :required if record.project_id.nil? && record.wip.nil?
    end
  end
end
