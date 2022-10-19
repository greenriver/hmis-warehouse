class Hmis::Hud::Validators::InventoryValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  def configuration
    Hmis::Hud::Inventory.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      record.errors.add :coc_code, :invalid, message: 'is invalid' unless ::HUD.valid_coc?(record.coc_code) && Hmis::Hud::ProjectCoc.where(coc_code: record.coc_code, project_id: record.project_id).exists?
    end
  end
end
