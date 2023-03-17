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

  def self.validate_entry_date(record)
    return unless record.entry_date.present?

    client_dob = record.client&.dob
    record.errors.add :entry_date, :invalid, message: "cannot be before DOB (#{client_dob.strftime('%m/%d/%Y')})" if client_dob.present? && client_dob > record.entry_date

    # TODO add a bunch more entry date validations
  end

  def validate(record)
    super(record) do
      self.class.validate_entry_date(record)
      record.errors.add :project_id, :required if record.project_id.nil? && record.wip.nil?
    end
  end
end
