###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class EtoBase < ActiveRecord::Base
  establish_connection :eto rescue nil
  self.abstract_class = true

  def readonly?
    true
  end
end
