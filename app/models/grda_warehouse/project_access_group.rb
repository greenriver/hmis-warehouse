###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Contrary to rails convention, this does not use STI

# Used to provide access to the projects within a project group
module GrdaWarehouse
  class ProjectAccessGroup < ProjectGroup
    self.table_name = :project_groups
  end
end
