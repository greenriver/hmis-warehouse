class Hmis::Hud::Validators::FunderValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Funder.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      # Other funder is required if 46 (other) is selected for funder
      record.errors.add :other_funder, :required, message: 'must exist' if record.funder == 46 && !record.other_funder.present?

      # End date must be after start date
      record.errors.add :end_date, :invalid, message: 'must be on or after start date' if record.end_date && record.start_date && record.end_date < record.start_date
    end
  end
end
