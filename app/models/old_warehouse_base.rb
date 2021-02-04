###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class OldWarehouseBase < ActiveRecord::Base
  begin
    establish_connection "#{Rails.env}_old_warehouse".parameterize.underscore.to_sym
  rescue StandardError
    nil
  end
  self.abstract_class = true
end
