###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
        format.html do
          @data = {}
          selected_project_ids = params[:selected_project_ids]&.map(&:to_i)&.compact || []
          project_scope.
            pluck(
              :id,
              :ProjectName,
              :computed_project_type,
              o_t[:OrganizationName].to_sql
            ).each do |id, p_name, type, o_name|
              @data[o_name] ||= []
              @data[o_name] << [
                "#{p_name} (#{HUD.project_type_brief(type)})",
                id,
                selected_project_ids.include?(id),
              ]
            end
          render layout: false
        end
      end
    end

    def select2ize data
      formatted = {
        results: []
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
      return formatted
    end

    def set_data_sources
      @data_source_ids = params[:data_source_ids].select(&:present?).map(&:to_i) rescue data_source_source.pluck(:id)
    end

    def set_organizations
      @organization_ids = params[:organization_ids].select(&:present?).map(&:to_i) rescue organization_source.pluck(:id)
    end

    def set_project_types
      @project_types = if params[:project_types].present? || params[:project_type_ids].present?
        []
      else
        HUD.project_types.keys
      end
      begin
        params[:project_types]&.select(&:present?)&.each do |type|
          @project_types += project_source::RESIDENTIAL_PROJECT_TYPES[type.to_sym]
        end
        @project_types = params[:project_type_ids]&.select(&:present?)&.map(&:to_i)
      rescue
        @project_types = HUD.project_types.keys
      end
      @project_types
    end

    def project_scope
      @project_scope = if params[:limited]
        project_source.visible_by(current_user)
      else
        project_source
      end
      @project_scope.joins(:data_source, :organization).
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