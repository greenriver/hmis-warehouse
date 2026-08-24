###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared user scoping for the User Directory report. The controller and the xlsx exports
# include this so the html listing and the download always cover the same users.
#
module UserDirectoryReport::DirectoryUsers
  extend ActiveSupport::Concern

  # `active` is a warehouse-only distinction. CasAccess::User has no active/inactive
  # scopes -- so the CAS listing gets its directory unfiltered.
  private def directory_users(user_model, active: true)
    scope = user_model.in_directory
    scope = active ? scope.active : scope.inactive if user_model == User
    searched(scope)
  end

  private def searched(scope)
    scope = scope.text_search(params[:q]) if params[:q].present?
    scope.order(:last_name, :first_name)
  end
end
