###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Option lists for the data source, organization, project, and CoC filters on
# the access control admin pages. These lists are not limited to what the
# current user can view, because admins assign access to entities they may not see.
module AccessControlEntityFilterOptions
  extend ActiveSupport::Concern
  include ArelHelper

  included do
    helper_method :data_source_filter_options, :organization_filter_options, :coc_code_filter_options
  end

  private def data_source_filter_options
    filter_data_source_scope.order(:name).pluck(:name, :id)
  end

  private def organization_filter_options
    show_confidential = current_user.can_view_confidential_project_names?
    GrdaWarehouse::Hud::Organization.
      where(data_source_id: filter_data_source_scope.select(:id)).
      joins(:data_source).
      order(ds_t[:name].asc, o_t[:OrganizationName].asc).
      pluck(ds_t[:name], o_t[:OrganizationName], o_t[:id], o_t[:confidential]).
      group_by(&:first).
      transform_values do |rows|
        rows.map do |_, name, id, confidential|
          name = GrdaWarehouse::Hud::Organization.confidential_organization_name if confidential && !show_confidential
          [name, id]
        end
      end
  end

  # Project lists can run to thousands of options, so the filter loads them
  # separately. Renders the same markup as Api::ProjectsController.
  def project_options
    selected_project_ids = Array.wrap(params.permit(selected_project_ids: [])[:selected_project_ids]).map(&:to_i)
    @data = project_filter_option_groups(selected_project_ids)
    render 'api/projects/index', layout: false
  end

  private def project_filter_option_groups(selected_project_ids)
    show_confidential = current_user.can_view_confidential_project_names?
    GrdaWarehouse::Hud::Project.
      where(data_source_id: filter_data_source_scope.select(:id)).
      joins(:organization, :data_source).
      order(o_t[:OrganizationName].asc, p_t[:ProjectName].asc).
      pluck(o_t[:id], o_t[:OrganizationName], ds_t[:short_name], p_t[:ProjectName], p_t[:id], p_t[:confidential], o_t[:confidential]).
      each_with_object({}) do |(org_id, org_name, ds_name, name, id, project_confidential, org_confidential), groups|
        org_name = GrdaWarehouse::Hud::Organization.confidential_organization_name if org_confidential && !show_confidential
        name = GrdaWarehouse::Hud::Project.confidentialize_name(current_user, name, project_confidential || org_confidential)
        (groups[[org_id, "#{org_name} (#{ds_name})"]] ||= []) << [name, id, selected_project_ids.include?(id)]
      end
  end

  private def coc_code_filter_options
    GrdaWarehouse::Hud::ProjectCoc.
      where(data_source_id: filter_data_source_scope.select(:id)).
      distinct.
      order(:CoCCode).
      pluck(:CoCCode).
      compact_blank
  end
end
