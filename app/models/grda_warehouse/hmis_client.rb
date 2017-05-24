class GrdaWarehouse::HmisClient < GrdaWarehouseBase
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  serialize :case_manager_attributes, Hash
  serialize :assigned_staff_attributes, Hash
  serialize :counselor_attributes, Hash
  serialize :outreach_counselor_attributes, Hash
end