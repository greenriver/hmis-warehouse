class OldWarehouseBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_old_warehouse".parameterize.underscore.to_sym rescue nil
  self.abstract_class = true
end
