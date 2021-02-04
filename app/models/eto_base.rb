###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# I don't believe this is in use
class EtoBase < ActiveRecord::Base
  begin
    establish_connection :eto
  rescue StandardError
    nil
  end
  self.abstract_class = true

  def readonly?
    true
  end
end
