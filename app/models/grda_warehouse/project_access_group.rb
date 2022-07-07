###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Used to provide access to the projects within a project group
module GrdaWarehouse
  class ProjectAccessGroup < ProjectGroup
    self.table_name = :project_groups
  end
end
