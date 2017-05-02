class GrdaWarehouse::HmisClient < GrdaWarehouseBase
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  serialize :case_manager_attributes, JSON
  serialize :assigned_staff_attributes, JSON
  serialize :counselor_attributes, JSON
  serialize :outreach_counselor_attributes, JSON
end