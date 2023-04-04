###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class ProjectClient < CasBase
    self.table_name = :project_clients
    belongs_to :client, class_name: 'CasAccess::Client', optional: true
    belongs_to :data_source, optional: true
  end
end
