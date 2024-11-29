###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# helper class to display versions for the admin user edit history page
class UserEditHistory::Versions

  attr_reader :user
  def initialize(user)
    @user = user
  end

  # Versions to display on the edit history page
  # * exclude login activity; it's too chatty for the history
  # * include changes made to the user record (or the hmis user alias)
  # * include changes to objects that reference this user (roles, groups, etc)
  def version_scope
    pt_a = GrPaperTrail::Version.arel_table
    scope = GrPaperTrail::Version.where(
      pt_a[:item_id].eq(user.id).and(pt_a[:item_type].in([User.sti_name, Hmis::User.sti_name])).
      or(pt_a[:referenced_user_id].eq(user.id)),
    )

    scope.where.not(id: login_version_scope.select(:id))
  end

  def wrap_display_versions(versions)
    users_by_id = build_user_lookup(versions)
    versions.map do |version|
      username = UserEditHistory::DisplayItem.new(version, users_by_id)
    end
  end

  protected

  # login-related activity
  def login_version_scope
    login_fields = [
      'current_sign_in_at',
      'current_sign_in_ip',
      'failed_at',
      'last_sign_in_at',
      'last_sign_in_ip',
      'sign_in_count',
      'updated_at'
    ]
    skip_scope = GrPaperTrail::Version.for_users.
      where(item_id: user.id).
      matching_object_change_fields(*login_fields)
  end

  # get an efficient lookup table for the users (whodunnit) that created these versions
  def build_user_lookup(versions)
    # fetch all the user records in one query
    user_ids = versions.flat_map do |version|
      [ version.clean_user_id, version.clean_true_user_id] unless version.anonymous?
    end

    # retrieve all users who might have been involved
    User.with_deleted.where(id: user_ids.compact.uniq).index_by(&:id)
  end
end
