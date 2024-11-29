###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# helper class for display the admin user edit history
class UserEditHistory::DisplayItem
  attr_reader :version, :username, :error, :changes
  delegate :created_at, to: :version

  # version is instance of GrPaperTrail::Version
  # users_by_id is preloaded user hash {id => user}
  def initialize(version, users_by_id)
    @version = version
    @username = compute_username(users_by_id)

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

  # represent who made the change
  def compute_username(users_by_id)
    return nil if version.anonymous?

    true_user = users_by_id[version.clean_true_user_id&.to_i]
    user = users_by_id[version.clean_user_id&.to_i]

    if true_user && user && true_user != user
      username = [true_user.name, user.name].join(' impersonating ')
    else
      username = user&.name
    end

    username&.presence || version.whodunnit.presence
  end
end
