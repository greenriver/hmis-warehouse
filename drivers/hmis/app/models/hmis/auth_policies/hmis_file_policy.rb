###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisFilePolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_view?
      # User can view the file if they have "can manage own" (global) AND it's their file, OR
      # if they have non-confidential access AND it's not confidential, OR
      # if they have confidential access AND it is confidential
      (file.user_id == user.id && global_permissions.include?(:can_manage_own_client_files)) ||
        (file_permissions.include?(:can_view_any_nonconfidential_client_files) && !file.confidential) ||
        (file_permissions.include?(:can_view_any_confidential_client_files) && file.confidential)
    end

    def can_manage?
      # User can manage (edit/delete) the file if they can view it, and:
      # - they have "can manage own" (global) AND it's their file, OR
      # - they can manage any files for this client
      can_view? && (
        (file.user_id == user.id && file_permissions.include?(:can_manage_own_client_files)) ||
        file_permissions.include?(:can_manage_any_client_files)
      )
    end

    def can_delete? = can_manage?

    protected

    def file
      resource
    end

    memoize def file_permissions
      if file.enrollment_id
        # If the file is connected to an enrollment, check the user's permissions on the enrollment's project
        context.project_permissions(file.enrollment.project_pk)
      else
        # Otherwise, check the user's permissions on the client,
        # which are based on their permissions at projects the client is enrolled in
        # (or global permissions, for unenrolled clients).
        context.client_permissions(file.client_id)
      end
    end

    def validate_resource!(arg)
      ensure_arg_type!(arg, Hmis::File)
    end
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_manage_own_client_files?
      # can_manage_own_client_files is a global permission.
      # If you have it anywhere in the data source, you can manage your own files on any client you can view
      # (even if you don't have it in any of that client's projects).
      global_permissions.include?(:can_manage_own_client_files)
    end

    # this is a functionality change. it's currently only used in the Client.files_viewable_by scope as an optimization.
    def can_index?
      global_permissions.include?(:can_manage_own_client_files) ||
        global_permissions.include?(:can_view_any_nonconfidential_client_files) ||
        global_permissions.include?(:can_view_any_confidential_client_files)
    end

    # Note, there is no "can_create?" permission on the global HmisFile policy; use the instance HmisClient policy's can_create_file? instead

    protected

    def validate_resource!(arg)
      ensure_arg_class!(arg, Hmis::File)
    end
  end
end

# todo @martha - what happens if you try to upload a confidential file, but you don't have access?
# both on this branch and on main: if you can upload a file, the UI does not prevent you from marking it confidential,
# even if that means you then can't view the file
