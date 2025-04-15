# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of CeParticipation for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class CeParticipation < GrdaWarehouse::Hud::CeParticipation
    default_scope { unscope where: paranoia_column }

    belongs_with_composite_keys :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', keys: [:ProjectID], optional: true
    alias_method :project, :project_with_deleted
  end
end
