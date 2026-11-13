###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTE: This provides an unscoped duplicate of CeParticipation for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class CeParticipation < GrdaWarehouse::Hud::CeParticipation
    default_scope { unscope where: paranoia_column }

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], optional: true
    alias_method :project, :project_with_deleted
  end
end
