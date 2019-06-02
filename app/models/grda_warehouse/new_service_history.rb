###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::NewServiceHistory < GrdaWarehouse::ServiceHistory
  self.table_name = 'new_service_history'
end