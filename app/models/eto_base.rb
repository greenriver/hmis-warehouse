###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# I don't believe this is in use
class EtoBase < ActiveRecord::Base
  establish_connection :eto rescue nil
  self.abstract_class = true

  def readonly?
    true
  end
end
