###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::Error < HmisCsvValidation::Base
  def self.type_name
    'Error'
  end

  def skip_row?
    true
  end
end
