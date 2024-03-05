###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Version < GrdaWarehouseBase
    include PaperTrail::VersionConcern

    belongs_to :hmis_client, class_name: 'Hmis::Hud::Client', foreign_key: :client_id, optional: true
    belongs_to :hmis_project, class_name: 'Hmis::Hud::Project', foreign_key: :project_id, optional: true

    # overlay object changes onto object
    def object_with_changes
      # create events have object_changes and a nil object
      result = object&.dup || {}
      result.merge!(object_changes.transform_values(&:last)) if object_changes.present?
      result
    end

    def clean_user_id
      [
        # User user_id if available
        user_id,
        # Otherwise use whodunnit
        whodunnit&.match?(/^\d+$/) ? whodunnit : nil,
        whodunnit&.match?(whodunnit_impersonator_pattern) ? whodunnit.sub(whodunnit_impersonator_pattern, '\2') : nil,
      ].find(&:present?)
    end

    def clean_true_user_id
      [
        # Don't return if not impersonating (i.e. user == true_user), use true_user_id if available
        user_id != true_user_id ? true_user_id : nil,
        # Use whodunnit if not
        whodunnit&.match?(whodunnit_impersonator_pattern) ? whodunnit.sub(whodunnit_impersonator_pattern, '\1') : nil,
      ].find(&:present?)
    end

    def whodunnit_impersonator_pattern
      # When impersonating a user, whodunnit is recorded as "<true_user> as <current_user>"
      /^(\d+) as (\d+)$/
    end
  end
end
