module Health
  class HealthFile < HealthBase    
    acts_as_paranoid
    belongs_to :user, required: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    
    mount_uploader :file, HealthFileUploader
  end
end  
