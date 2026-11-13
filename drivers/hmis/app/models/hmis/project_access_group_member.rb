###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This DB view finds project and access group relationships. It includes access groups that relate to the project
# indirectly (via organization, project groups, etc)
module Hmis
  class ProjectAccessGroupMember < GrdaWarehouseBase
    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :access_group, class_name: 'Hmis::AccessGroup' # crosses db boundary
  end
end
