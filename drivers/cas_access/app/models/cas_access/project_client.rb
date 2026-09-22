###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/warehouse/cas-integration.md
module CasAccess
  class ProjectClient < CasBase
    self.table_name = :project_clients
    belongs_to :client, class_name: 'CasAccess::Client', optional: true
    belongs_to :data_source, optional: true
  end
end
