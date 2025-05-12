###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# helper class for the user edit history page
class UserEditHistory::Versions
  attr_reader :user
  def initialize(user)
    @user = user
  end

  # Versions to display on the edit history page
  # * exclude login activity; it's too chatty for the history
  # * include changes made to the user record itself (or the hmis user alias)
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
      UserEditHistory::DisplayItem.new(version, users_by_id)
    end
  end

  protected

  # login-related activity
  def login_version_scope
    login_fields = [
      'current_sign_in_at',
      'current_sign_in_ip',
      'failed_attempts',
      'last_sign_in_at',
      'last_sign_in_ip',
      'sign_in_count',
      'updated_at',
    ]
    GrPaperTrail::Version.for_users.
      where(item_id: user.id).
      matching_object_change_fields(*login_fields)
  end

  # lookup table for the users that created these versions, avoids n+1
  def build_user_lookup(versions)
    # fetch all the user records in one query
    user_ids = versions.flat_map do |version|
      [version.clean_user_id, version.clean_true_user_id] unless version.anonymous?
    end

    # retrieve all users who might have been involved
    user_ids = user_ids.compact.map(&:to_i).uniq
    User.with_deleted.where(id: user_ids).index_by(&:id)
  end
end
