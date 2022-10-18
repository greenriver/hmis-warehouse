class Hmis::Hud::Validators::FunderValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  def configuration
    Hmis::Hud::Funder.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      # Other funder is required if 46 (other) is selected for funder
      record.errors.add :other_funder, :required, message: 'must exist' if record.funder == 46 && !record.other_funder.present?
    end
  end
end
