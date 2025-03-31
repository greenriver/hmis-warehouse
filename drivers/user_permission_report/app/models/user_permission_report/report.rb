###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

# This class is used to generate the data for excel exports of the User Permission Report.
# This currently only generates the HMIS export data, but could be extended to generate the Warehouse export data as well.
module UserPermissionReport
  class Report
    def initialize(user)
      @current_user = user
    end

    # Data for HMIS sheet in excel export
    def hmis_data
      return unless HmisEnforcement.hmis_enabled?
      return unless @current_user.as_hmis_user.can_audit_users?

      hmis_users = Hmis::User.order(:last_name, :first_name).
        includes(access_controls: [:access_group, :user_group, :role])

      warehouse_users = User.all.index_by(&:id)

      hmis_users.map do |user|
        next unless user.access_controls.any? # non-HMIS user

        # One row per Access Control that this User belongs to
        user.access_controls.map do |access_control|
          entities = hmis_collection_entities(access_control.access_group_id)

          {
            name: user.name,
            email: user.email,
            user_id: user.id,
            status: warehouse_users[user.id].overall_status(@current_user).join('; '),
            # TODO(#7486) include last sign in date for HMIS specifically
            # last_hmis_login: user.last_hmis_login&.to_time&.to_fs(:db),
            role_name: access_control.role.name,
            collection_name: access_control.access_group.name,
            inherited_from_user_group: access_control.user_group.name,
            role_permissions: access_control.role.granted_permissions.map { |perm| perm.to_s.humanize }.join(', '),
            data_sources_in_collection: entities[:data_sources].join("\n").presence,
            organizations_in_collection: entities[:organizations].join("\n").presence,
            projects_in_collection: entities[:projects].join("\n").presence,
          }
        end
      end.compact.flatten(1)
    end

    private

    def hmis_collection_entities(collection_id)
      # { collection_id => { data_sources: [names of data sources], organizations: [names of orgs], projects: [names of projects] } }
      @entities_by_collection_id ||= Hmis::AccessGroup.includes(:data_sources, :organizations, :projects).
        map { |ag| [ag.id, ag.entity_names] }.to_h

      @entities_by_collection_id[collection_id]
    end
  end
end
