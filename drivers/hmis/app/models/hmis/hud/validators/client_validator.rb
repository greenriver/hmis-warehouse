class Hmis::Hud::Validators::ClientValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :Gender,
    :Race,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Client.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      record.errors.add :first_name, :required if record.first_name.blank? && record.last_name.blank?
      record.errors.add :last_name, :required if record.first_name.blank? && record.last_name.blank?
      record.errors.add :gender, :required if !skipped_attributes(record).include?(:gender) && ::HudUtility.gender_id_to_field_name.except(8, 9, 99).values.any? { |field| record.send(field).nil? }
      record.errors.add :race, :required if !skipped_attributes(record).include?(:race) && ::HudUtility.races.except('RaceNone').keys.any? { |field| record.send(field).nil? }
    end
  end
end
