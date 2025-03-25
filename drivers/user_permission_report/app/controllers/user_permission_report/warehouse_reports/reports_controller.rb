###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserPermissionReport::WarehouseReports
  class ReportsController < ApplicationController
    before_action :set_group_associations

    def index
      @users = User.
        order(:last_name, :first_name).
        includes(:roles, access_groups: @group_associations.keys)
      respond_to do |format|
        format.html do
          @users = @users.text_search(params[:q]) if params[:q].present?
          @pagy, @users = pagy(@users)
        end
        format.xlsx do
          date = Date.current.strftime('%Y-%m-%d')
          filename = "user-permissions-#{date}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def set_group_associations
      @group_associations = User.group_associations
    end

    def associated_items(user, meth)
      return nil unless @group_associations.keys.include? meth

      items = user.access_groups.map { |g| g.public_send(meth) }.flatten.uniq
      {
        count: items.count,
        names: items.map(&:name),
        total: @group_associations[meth].count,
      }
    end
    helper_method :associated_items

    def hmis_access_report_rows
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
            status: warehouse_users[user.id].overall_status(current_user).join('; '),
            last_hmis_login: most_recent_hmis_login(user)&.to_time&.to_fs(:db),
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
    helper_method :hmis_access_report_rows

    private def hmis_collection_entities(collection_id)
      # { collection_id => { data_sources: [names of data sources], organizations: [names of orgs], projects: [names of projects] } }
      @entities_by_collection_id ||= Hmis::AccessGroup.includes(:data_sources, :organizations, :projects).
        map { |ag| [ag.id, ag.entity_names] }.to_h

      @entities_by_collection_id[collection_id]
    end

    private def most_recent_hmis_login(user)
      return unless HmisEnforcement.hmis_enabled?

      # Most recent successful HMIS login for each user
      @recent_hmis_logins ||= LoginActivity.successful.hmis_logins.
        select('DISTINCT ON (user_id) user_id, created_at').
        order(:user_id, created_at: :desc).
        map { |r| [r.user_id, r.created_at] }.to_h

      @recent_hmis_logins[user.id]
    end
    helper_method :most_recent_hmis_login

    private def most_recent_warehouse_login(user)
      # for non-HMIS installations, we can use the devise current_sign_in_at directly because there is only one scope
      return user.current_sign_in_at unless HmisEnforcement.hmis_enabled?

      # Most recent successful Warehouse login for each user
      @recent_warehouse_logins ||= LoginActivity.successful.warehouse_logins.
        select('DISTINCT ON (user_id) user_id, created_at').
        order(:user_id, created_at: :desc).
        map { |r| [r.user_id, r.created_at] }.to_h

      @recent_warehouse_logins[user.id]
    end
    helper_method :most_recent_warehouse_login
  end
end
