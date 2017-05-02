class OldWarehouseBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_old_warehouse".parameterize.underscore.to_sym
  self.abstract_class = true
end
