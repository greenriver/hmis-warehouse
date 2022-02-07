###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Provides a list of projects that belong to to the selected
# data sources and organizations
# optionally, limits the list to only those a user can see
# Default to all
module Api
  class ProjectsController < ApplicationController
    include ArelHelper

    def index
      respond_to do |format|
        @data = {}
        selected_project_ids = project_params[:selected_project_ids]&.
          map(&:to_i)&.
          compact || []
        project_scope.
          pluck(
            :id,
            :ProjectName,
            :computed_project_type,
            o_t[:OrganizationName],
            o_t[:id],
          ).each do |id, p_name, type, o_name, o_id|
            name = GrdaWarehouse::Hud::Project.confidentialize(name: p_name)
            name = p_name if can_view_confidential_enrollment_details?
            @data[[o_id, o_name]] ||= []
            @data[[o_id, o_name]] << [
              "#{name} (#{HUD.project_type_brief(type)})",
              id,
              selected_project_ids.include?(id),
            ]
          end
        format.html do
          render layout: false
        end
        format.json do
          # NOTE: pre-selection does not work if this is fetched via AJAX by select2
          render json: select2ize(@data)
        end
      end
    end

    def select2ize(data)
      formatted = {
        results: [],
      }
      data.each do |(_, org_name), projects|
        group = {
          text: org_name,
          children: [],
        }
        projects.each do |name, id, selected|
          proj = { id: id, text: name }
          proj[:selected] = selected if selected
          group[:children] << proj
        end
        formatted[:results] << group
      end
      formatted
    end

    private def data_source_ids
      ds_ids = project_params[:data_source_ids].select(&:present?) if project_params[:data_source_ids].present?
      @data_source_ids ||= ds_ids.map(&:to_i) if ds_ids.present?
    end

    private def organization_ids
      org_ids = project_params[:organization_ids].select(&:present?) if project_params[:organization_ids].present?
      @organization_ids ||= if org_ids.present?
        org_ids.map(&:to_i)
      else
        organization_source.select(:id)
      end
    end

    private def project_types
      return HUD.project_types.keys unless project_params[:project_types].present? || project_params[:project_type_ids].present?

      @project_types ||= begin
        types = []

        if project_params[:project_types].present?
          project_params[:project_types]&.select(&:present?)&.map(&:to_sym)&.each do |type|
            types += project_source::RESIDENTIAL_PROJECT_TYPES[type]
          end
        end
        if project_params[:project_type_ids].present?
          types += project_params[:project_type_ids]&.
            select(&:present?)&.
            map(&:to_i)
        end
        types
      end
    end

    def project_params
      params.permit(
        :limited,
        data_source_ids: [],
        organization_ids: [],
        project_types: [],
        project_type_ids: [],
        selected_project_ids: [],
      )
    end

    private def project_scope
      @project_scope ||= begin
        scope = project_source.viewable_by(current_user).
          joins(:data_source, :organization).
          with_project_type(project_types)
        scope = scope.merge(data_source_source.where(id: data_source_ids)) if data_source_ids.present?
        scope = scope.merge(organization_source.where(id: organization_ids)) if organization_ids.present?
        scope
      end
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def data_source_source
      GrdaWarehouse::DataSource
    end

    def organization_source
      GrdaWarehouse::Hud::Organization
    end
  end
end
