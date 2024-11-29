###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# helper class for display the admin user edit history
class UserEditHistory::DisplayItem
  attr_reader :version, :username, :impersonating, :error, :changes
  delegate :created_at, to: :version

  # version is instance of GrPaperTrail::Version
  # users_by_id is preloaded user hash {id => user}
  def initialize(version, users_by_id)
    @version = version
    @username = compute_username(users_by_id, version.clean_true_user_id) || version.whodunnit.presence
    @impersonating = compute_username(users_by_id, version.clean_user_id) if version.impersonating?

    begin
      # could fail if the model referenced by item_type no longer exists
      klass = version.item_type.constantize
    rescue NameError
      @error = true
    end

    begin
      # * could fail to deserialize yaml
      # * could fail during computed fallback when reifying old records
      changeset = version.changes_with_computed_fallback unless @error
    rescue StandardError
      @error = true
    end

    @changes = klass.describe_changes(version, changeset) unless @error
  end

  protected

  # true user who made the change
  def compute_username(users_by_id, user_id)
    return if version.anonymous?
    return unless user_id

    user = users_by_id[user_id.to_i]
    user&.name || "User ID #{user_id}"
  end
end
