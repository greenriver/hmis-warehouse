class Hmis::Hud::Validators::HealthAndDvValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  def configuration
    Hmis::Hud::HealthAndDv.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      record.errors.add :when_occurred, :required if record.domestic_violence_victim == 1 && record.when_occurred.blank?
      record.errors.add :currently_fleeing, :required if record.domestic_violence_victim == 1 && record.currently_fleeing.blank?
    end
  end
end
