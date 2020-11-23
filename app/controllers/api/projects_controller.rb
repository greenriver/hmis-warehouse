###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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
    before_action :set_data_sources
    before_action :set_organizations
    before_action :set_project_types

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
          ).each do |id, p_name, type, o_name|
            @data[o_name] ||= []
            @data[o_name] << [
              "#{p_name} (#{HUD.project_type_brief(type)})",
              id,
              selected_project_ids.include?(id),
            ]
          end
        format.html do
          render layout: false
        end
        format.json do
          render json: select2ize(@data)
        end
      end
    end

    def select2ize(data)
      formatted = {
        results: [],
      }
      data.each do |org_name, projects|
        group = {
          text: org_name,
          children: [],
        }
        projects.each do |name, id|
          group[:children] << { id: id, text: name }
        end
        formatted[:results] << group
      end
      formatted
    end

    def set_data_sources
      ds_ids = project_params[:data_source_ids].select(&:present?) if project_params[:data_source_ids].present?
      @data_source_ids = if ds_ids.present?
        ds_ids.map(&:to_i)
      else
        data_source_source.pluck(:id)
      end
    end

    def set_organizations
      org_ids = project_params[:organization_ids].select(&:present?) if project_params[:organization_ids].present?
      @organization_ids = if org_ids.present?
        org_ids.map(&:to_i)
      else
        organization_source.pluck(:id)
      end
    end

    def set_project_types
      if project_params[:project_types].present? || project_params[:project_type_ids].present?
        @project_types = []
      else
        # none provided, limit to known types
        @project_types = HUD.project_types.keys
        return
      end

      if project_params[:project_types].present?
        project_params[:project_types]&.select(&:present?)&.map(&:to_sym)&.each do |type|
          @project_types += project_source::RESIDENTIAL_PROJECT_TYPES[type]
        end
      end
      if project_params[:project_type_ids].present?
        @project_types += project_params[:project_type_ids]&.
          select(&:present?)&.
          map(&:to_i)
      end

      @project_types
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

    def project_scope
      @project_scope = project_source.viewable_by(current_user).
        joins(:data_source, :organization).
        where(computed_project_type: @project_types).
        merge(data_source_source.where(id: @data_source_ids)).
        merge(organization_source.where(id: @organization_ids))
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
