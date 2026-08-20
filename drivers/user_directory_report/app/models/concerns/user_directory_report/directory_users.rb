###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared user scoping for the User Directory report. The controller and both xlsx exports
# include this so the html listing and the download always cover the same users and report
# the same status for each of them.
#
module UserDirectoryReport::DirectoryUsers
  extend ActiveSupport::Concern

  private def directory_users(user_model)
    scope = user_model.in_directory
    scope = scope.text_search(params[:q]) if params[:q].present?
    scope.order(:last_name, :first_name)
  end

  # The `active` column is only part of what makes a user active: the `inactive` scope also
  # covers accounts that have expired or whose last activity has aged out, so the column's
  # `active?` predicate disagrees with the scope for those users. Collect the ids the scope
  # matches once, up front, and let each row ask this set rather than re-deriving the rule.
  private def inactive_user_ids(user_model)
    user_model.in_directory.inactive.pluck(:id).to_set
  end
end
