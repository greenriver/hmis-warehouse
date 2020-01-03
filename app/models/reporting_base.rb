###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ReportingBase < ActiveRecord::Base
  establish_connection DB_REPORTING
  self.abstract_class = true
end
