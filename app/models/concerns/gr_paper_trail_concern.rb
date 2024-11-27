###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# common behaviors both app and warehouse database version models
module GrPaperTrailConcern
  extend ActiveSupport::Concern
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
      return unless whodunnit&.match?(whodunnit_impersonator_pattern)

      whodunnit.sub(whodunnit_impersonator_pattern, '\1').presence
    end

    def whodunnit_impersonator_pattern
      # When impersonating a user, whodunnit is recorded as "<true_user> as <current_user>"
      /^(\d+) as (\d+)$/
    end
end
