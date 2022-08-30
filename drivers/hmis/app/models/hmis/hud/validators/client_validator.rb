class Hmis::Hud::Validators::ClientValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :Gender,
    :Race,
  ].freeze

  def configuration
    Hmis::Hud::Client.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      record.errors.add :gender, :required if !skipped_attributes(record).include?(:gender) && ::HUD.gender_id_to_field_name.except(8, 9, 99).values.any? { |field| record.send(field).nil? }
      record.errors.add :race, :required if !skipped_attributes(record).include?(:race) && ::HUD.races.except('RaceNone').keys.any? { |field| record.send(field).nil? }
    end
  end
end
