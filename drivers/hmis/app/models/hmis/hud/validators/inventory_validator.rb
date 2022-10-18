class Hmis::Hud::Validators::InventoryValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  def configuration
    Hmis::Hud::Inventory.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      record.errors.add :coc_code, :invalid, message: 'Invalid CoC code' if !skipped_attributes(record).include?(:coc_code) && !Hmis::Hud::ProjectCoc.where(coc_code: record.coc_code, project_id: record.project_id).exists?
    end
  end
end
