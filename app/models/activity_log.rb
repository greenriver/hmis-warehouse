class ActivityLog < ActiveRecord::Base

  def clean_object_name
    item_model&.gsub('GrdaWarehouse::Hud::', '')
  end

end