###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectPassFail
  class Client < GrdaWarehouseBase
    self.table_name = :project_pass_fails_clients
    belongs_to :project_pass_fail, inverse_of: :clients
    belongs_to :project, inverse_of: :clients
  end
end
