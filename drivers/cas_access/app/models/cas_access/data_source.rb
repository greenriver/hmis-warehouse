###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class DataSource < CasBase
    self.table_name = :data_sources
    has_many :project_clients
  end
end
