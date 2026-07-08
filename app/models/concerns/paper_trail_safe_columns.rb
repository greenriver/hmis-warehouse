###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Best-effort accessors for a PaperTrail version's serialized `object` / `object_changes` columns.
module PaperTrailSafeColumns
  # Errors that can surface when deserializing an old version's YAML. A record can reference a class
  # that was defined/permitted when the version was written but is gone now: unsafe_load raises
  # ArgumentError/NameError/TypeError for a removed constant, safe_load raises Psych::DisallowedClass,
  # and malformed YAML raises Psych::SyntaxError (both Psych::Exception). Callers doing best-effort
  # audit display want nil, not an exception.
  DESERIALIZATION_ERRORS = [Psych::Exception, ArgumentError, NameError, TypeError].freeze

  # Best-effort deserialization of the `object` column; nil (and a log line) instead of raising.
  def safe_object
    object
  rescue *DESERIALIZATION_ERRORS => e
    Rails.logger.warn("#{self.class.name}#safe_object: failed to load object for version #{id}: #{e.message}")
    nil
  end

  # Best-effort deserialization of the `object_changes` column; nil (and a log line) instead of raising.
  def safe_object_changes
    object_changes
  rescue *DESERIALIZATION_ERRORS => e
    Rails.logger.warn("#{self.class.name}#safe_object_changes: failed to load object_changes for version #{id}: #{e.message}")
    nil
  end
end
