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

  def self.hmis_validate(record, ignore_warnings: false, user: nil)
    errors = HmisErrors::Errors.new

    if record.entry_date.present?
      dob = record.client&.dob
      safe_dob = record.client&.safe_dob(user)
      errors.add :entry_date, :out_of_range, message: 'cannot be in the future' if record.entry_date.future?
      errors.add :entry_date, :out_of_range, message: "cannot be before client's DOB" if dob.present? && dob > record.entry_date
      errors.add :entry_date, :information, severity: :warning, message: "is equal to client's DOB" if safe_dob.present? && safe_dob == record.entry_date
      errors.add :entry_date, :information, severity: :warning, message: 'is over 30 days ago' if record.entry_date < (Date.today - 30.days)
    end

    return errors.errors.reject(&:warning?) if ignore_warnings

    errors.errors
  end

  def validate(record)
    super(record) do
      record.errors.add :project_id, :required if record.project_id.nil? && record.wip.nil?
    end
  end
end
