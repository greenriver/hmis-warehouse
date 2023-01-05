###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Project for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Project < GrdaWarehouse::Hud::Project
    default_scope { unscope where: paranoia_column }

    has_many :project_cocs_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::ProjectCoc', foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id]
    alias_attribute :project_cocs, :project_cocs_with_deleted
  end
end
