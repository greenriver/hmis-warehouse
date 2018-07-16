class GrdaWarehouse::DashboardExportReport < GrdaWarehouseBase
  belongs_to :file, class_name: GrdaWarehouse::DashboardExportFile.name

  def complete?
    completed_at.present?
  end

  def user_name
    if user_id.present?
      User.find(user_id).name
    else
      ''
    end
  end

  def display_coc_code
    if coc_code.present?
      coc_code
    else
      "All"
    end
  end

  def status
    if complete?
      "Completed"
    elsif started_at.present?
      "Started"
    else
      "Queued"
    end
  end
end
