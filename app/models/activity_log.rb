class ActivityLog < ActiveRecord::Base

  belongs_to :user

  def clean_object_name
    item_model&.gsub('GrdaWarehouse::Hud::', '')
  end
end