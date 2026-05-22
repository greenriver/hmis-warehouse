###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisFilePolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_view_unredacted?
      # User can view the file contents if:
      # - they have "can manage own" (global) AND it's their file, OR
      # - they have non-confidential access AND it's not confidential, OR
      # - they have confidential access AND it is confidential.
      #
      # NOTE: If the user can view nonconfidential files but not confidential files,
      # can_view_unredacted? returns false but the file IS included in the `File#viewable_by` scope.
      # not "is this file's existence visible to the user at all?"
      # See comments on the `File#viewable_by` scope.
      (file.user_id == user.id && global_permissions.include?(:can_manage_own_client_files)) ||
        (file_permissions.include?(:can_view_any_nonconfidential_client_files) && !file.confidential) ||
        (file_permissions.include?(:can_view_any_confidential_client_files) && file.confidential)
    end

    def can_manage?
      # User can manage (edit/delete) the file if they can view it, and:
      # - they have "can manage any" granted through the file's client/enrollment, OR
      # - they have "can manage own" (global) AND it's their file
      can_view_unredacted? && (
        file_permissions.include?(:can_manage_any_client_files) ||
        (file.user_id == user.id && global_permissions.include?(:can_manage_own_client_files))
      )
    end

    def can_delete? = can_manage?
    def can_edit? = can_manage?

    protected

    def file
      resource
    end

    memoize def file_permissions
      # File belongs to a client and optionally to an enrollment.
      if file.enrollment_id
        # If the file is connected to an enrollment, permissions come from the enrollment's project.
        context.project_permissions(file.enrollment.project_pk)
      else
        # Otherwise, permissions come from the client, which aggregates permissions across the
        # projects the client is enrolled in, falling back to global permissions for unenrolled clients.
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

    def can_index?
      global_permissions.include?(:can_manage_own_client_files) ||
        global_permissions.include?(:can_view_any_nonconfidential_client_files) ||
        global_permissions.include?(:can_view_any_confidential_client_files)
    end

    # Note, there is no "can_create?" permission on the global HmisFile policy. Use the instance HmisClient policy's can_create_file? instead

    protected

    def validate_resource!(arg)
      ensure_arg_class!(arg, Hmis::File)
    end
  end
end
