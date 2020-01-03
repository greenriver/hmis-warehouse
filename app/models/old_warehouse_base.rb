###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class OldWarehouseBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_old_warehouse".parameterize.underscore.to_sym rescue nil
  self.abstract_class = true
end
