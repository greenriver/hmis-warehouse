class Hmis::Hud::Validators::ExitValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Exit.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def self.hmis_validate(record, role: nil, **_)
    errors = HmisErrors::Errors.new

    if record.exit_date.present? && role == :EXIT
      errors.add :exit_date, :out_of_range, message: 'cannot be in the future' if record.exit_date.future?
      errors.add :exit_date, :information, severity: :warning, message: 'is over 30 days ago' if record.exit_date < (Date.today - 30.days)
    end

    errors.errors
  end

  def validate(record)
    super(record) do
      entry_date = record.enrollment&.entry_date
      record.errors.add :exit_date, :invalid, message: "cannot be before entry date (#{entry_date.strftime('%m/%d/%Y')})" if entry_date.present? && record.exit_date.present? && record.exit_date < entry_date
    end
  end
end
