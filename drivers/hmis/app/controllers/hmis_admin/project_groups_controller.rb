###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisAdmin
  class ProjectGroupsController < ApplicationController
    include EnforceHmisEnabled

    before_action :require_hmis_admin_access! # for now, only HMIS admins can view/edit these
    before_action :set_project_group, only: [:edit, :update, :destroy, :show]

    def index
      @project_groups = Hmis::ProjectGroup.all.preload(:data_source, :projects)
      @project_groups = @project_groups.text_search(params[:q]) if params[:q].present?
      @pagy, @project_groups = pagy(@project_groups)
    end

    def new
      @project_group = project_group_source.new
    end

    # When creating a new Project Group, user must specify name and data source. Criteria is set on update only.
    def create
      @project_group = project_group_source.new(
        name: create_project_group_params[:name],
        data_source_id: create_project_group_params[:data_source_id],
        inclusion_criteria: {}.to_json, # empty to start
      )
      raise 'must be hmis data source' unless @project_group.data_source.hmis?

      project_group_source.transaction do
        @project_group.save!
        redirect_to hmis_admin_project_group_path(@project_group), notice: 'Project Group was successfully created.'
      rescue Exception => e
        flash[:error] = @project_group.errors.full_messages.join(', ') if @project_group.errors.any?
        flash[:error] ||= e.message
        render action: :new
      end
    end

    def edit
    end

    def show
    end

    def update
      p = project_group_params

      @project_group.name = p[:name]
      @project_group.inclusion_criteria = p[:inclusion_criteria].to_json
      @project_group.exclusion_criteria = p[:exclusion_criteria].to_json

      project_group_source.transaction do
        @project_group.save!
        @project_group.maintain_projects!
        redirect_to hmis_admin_project_group_path(@project_group), notice: 'Project Group was successfully updated.'
      rescue Exception => e
        flash[:error] = @project_group.errors.full_messages.join(', ') if @project_group.errors.any?
        flash[:error] ||= e.message
        render action: :edit
      end
    end

    private

    def project_group_source
      Hmis::ProjectGroup
    end

    def project_group_scope
      project_group_source.
        editable_by(current_user).
        includes(:projects).order(name: :asc)
    end

    def set_project_group
      @project_group = Hmis::ProjectGroup.find(params[:id])
    end

    def create_project_group_params
      params.require(:filters).permit(
        :name,
        :data_source_id,
      )
    end

    def project_group_params
      permitted_criteria_params = {
        project_ids: [],
        data_source_ids: [],
        organization_ids: [],
        project_type_numbers: [],
      }
      params.require(:filters).permit(
        :name,
        inclusion_criteria: permitted_criteria_params,
        exclusion_criteria: permitted_criteria_params,
      )
    end
  end
end
