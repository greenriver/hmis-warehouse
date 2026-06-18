###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class DataSource < CasBase
    self.table_name = :data_sources
    has_many :project_clients
  end
end
