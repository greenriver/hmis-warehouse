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

  # Every HMIS installation on this deployment; empty when HMIS is off, which is what
  # hides the HMIS column from both the screen and the spreadsheet.
  private def hmis_data_sources
    @hmis_data_sources ||= GrdaWarehouse::DataSource.enabled_hmis_data_sources
  end

  # The HMIS installations this user can reach, empty when they can reach none.
  private def hmis_data_sources_for(user)
    accessible_ids = hmis_access_by_user_id.fetch(user.id, [])
    hmis_data_sources.select { |hmis_ds| accessible_ids.include?(hmis_ds.id) }
  end

  private def hmis_access_by_user_id
    return @hmis_access_by_user_id if defined?(@hmis_access_by_user_id)

    @hmis_access_by_user_id = hmis_data_sources.any? ? Hmis::User.accessible_hmis_data_source_ids_by_user_id : {}
  end
end
