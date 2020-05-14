class GrdaWarehouse::UserClientPermission < GrdaWarehouseBase
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  validates :user_id, presence: true
end
