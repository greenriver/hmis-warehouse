class Hmis::Hud::Validators::InventoryValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Inventory.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      # CoC code must be valid for project
      record.errors.add :coc_code, :invalid, message: 'is invalid' if record.coc_code.present? && (!::HudUtility.valid_coc?(record.coc_code) || !Hmis::Hud::ProjectCoc.where(coc_code: record.coc_code, project_id: record.project_id).exists?)

      # Unit and bed counts must be non-negative
      [
        :bed_inventory,
        :unit_inventory,
        :ch_vet_bed_inventory,
        :youth_vet_bed_inventory,
        :vet_bed_inventory,
        :ch_youth_bed_inventory,
        :youth_bed_inventory,
        :ch_bed_inventory,
        :other_bed_inventory,
      ].each do |field|
        record.errors.add field, :invalid, message: 'must be greater than or equal to 0' if record.send(field)&.negative?
      end

      # End date must be after start date
      end_date_before_start_date = record.inventory_end_date && record.inventory_start_date && record.inventory_end_date < record.inventory_start_date
      record.errors.add :inventory_end_date, :invalid, message: 'must be on or after start date' if end_date_before_start_date

      unless end_date_before_start_date
        # Validate that start/end dates are within the project operating period
        project_start = record.project&.operating_start_date
        project_end = record.project&.operating_end_date

        within_project_msg = "must be within project operating period (#{project_start&.strftime('%m/%d/%Y')}-#{project_end&.strftime('%m/%d/%Y')})"
        too_early_msg = "must be on or after project start date (#{project_start&.strftime('%m/%d/%Y')})"

        # validate start date
        if project_start && project_end && record.inventory_start_date && !record.inventory_start_date.between?(project_start, project_end)
          record.errors.add :inventory_start_date, :invalid, message: within_project_msg
        elsif project_start && record.inventory_start_date && record.inventory_start_date.before?(project_start)
          record.errors.add :inventory_start_date, :invalid, message: too_early_msg
        end

        # validate end date
        if project_start && project_end && record.inventory_end_date && !record.inventory_end_date.between?(project_start, project_end)
          record.errors.add :inventory_end_date, :invalid, message: within_project_msg
        elsif project_start && record.inventory_end_date && record.inventory_end_date.before?(project_start)
          record.errors.add :inventory_end_date, :invalid, message: too_early_msg
        end
      end
    end
  end
end
