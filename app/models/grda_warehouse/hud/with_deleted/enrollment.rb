###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Enrollment for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    default_scope {unscope where: paranoia_column}

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id]

    belongs_to :client_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Client', foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id]
  end
end