###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module UserPermissions
  extend ActiveSupport::Concern
  include ArelHelper

  included do
    # Some permissions are not simple booleans on the role
    # this provides a means of exposing those at the view level
    # for everything listed here there should also be a method below
    def self.additional_permissions
      [
        :can_see_admin_menu,
        :can_see_raw_hmis_data,
        :can_receive_secure_files,
        :can_assign_or_view_users_to_clients,
        :can_view_clients_or_window,
        :window_file_access,
        :can_access_vspdat_list,
        :can_create_or_modify_vspdat,
        :can_access_youth_intake_list,
        :can_edit_some_youth_intakes,
        :can_edit_window_client_notes_or_own_window_client_notes,
        :can_view_any_reports,
        :can_view_user_audit_report,
        :can_view_client_and_history,
        :can_view_or_edit_client_health,
        :can_view_imports_projects_or_organizations,
        :can_edit_projects_or_everything,
        :can_edit_data_sources_or_everything,
        :can_view_some_secure_files,
      ].freeze
    end

    def can_see_admin_menu?
      can_edit_users? || can_edit_translations? || can_administer_health? || can_manage_config?
    end

    # You must have permission to upload, and access to at least one Data Source
    def can_see_raw_hmis_data?
      can_upload_hud_zips? && GrdaWarehouse::UserViewableEntity.data_source.where(user_id: id).exists?
    end

    def can_receive_secure_files?
      can_view_assigned_secure_uploads? || can_view_all_secure_uploads?
    end

    def self.can_receive_secure_files?
      can_view_assigned_secure_uploads || can_view_all_secure_uploads
    end

    def can_assign_or_view_users_to_clients?
      can_assign_users_to_clients? || can_view_client_user_assignments?
    end

    def can_view_clients_or_window?
      can_view_client_window? || can_view_clients?
    end

    def window_file_access?
      can_see_own_file_uploads? || can_manage_window_client_files?
    end

    def can_access_vspdat_list?
      GrdaWarehouse::Vispdat::Base.any_visible_by?(current_user)
    end

    def can_create_or_modify_vspdat?
      GrdaWarehouse::Vispdat::Base.any_modifiable_by(current_user)
    end

    def can_access_youth_intake_list?
      GrdaWarehouse::YouthIntake::Base.any_visible_by?(current_user)
    end

    def can_edit_some_youth_intakes?
      GrdaWarehouse::YouthIntake::Base.any_modifiable_by?(current_user)
    end

    def can_edit_window_client_notes_or_own_window_client_notes?
      can_edit_window_client_notes? || can_see_own_window_client_notes? || can_edit_client_notes?
    end

    def can_view_any_reports?
      can_view_all_reports? || can_view_assigned_reports?
    end

    def can_view_user_audit_report?
      can_manage_agency? || can_manage_all_agencies?
    end

    def can_view_client_and_history?
      can_view_clients? && can_view_client_history_calendar?
    end

    def can_view_or_edit_client_health?
      can_view_client_health? || can_edit_client_health?
    end

    def can_view_imports_projects_or_organizations?
      can_view_imports? || can_view_projects? || can_view_organizations? || can_edit_anything_super_user?
    end

    def can_edit_projects_or_everything?
      can_edit_projects? || can_edit_anything_super_user?
    end

    def can_edit_data_sources_or_everything?
      can_edit_data_sources? || can_edit_anything_super_user?
    end

    def can_view_some_secure_files?
      can_view_all_secure_uploads? || can_view_assigned_secure_uploads?
    end
  end
end