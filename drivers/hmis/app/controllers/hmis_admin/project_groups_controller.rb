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
    before_action :set_project_group, only: [:edit, :destroy]

    def index
      @project_groups = Hmis::ProjectGroup.all
      @project_groups = @project_groups.text_search(params[:q]) if params[:q].present?
      @pagy, @project_groups = pagy(@project_groups)
    end

    def new
      @project_group = project_group_source.new
    end

    def create
      @project_group = project_group_source.new(
        name: project_group_params[:name],
      )
      project_group_source.transaction do
        @project_group.save!
        @project_group.maintain_projects!
      rescue Exception => e
        flash[:error] = e.message
        render action: :new
        return
      end
      respond_with(@project_group, location: edit_hmis_admin_project_group_path(@project_group.id))
    end

    # GET /hmis/project_groups/:id/edit
    def edit
    end

    # PATCH/PUT /hmis/project_groups/:id
    def update
      if @project_group.update(project_group_params)
        redirect_to hmis_project_group_path(@project_group), notice: 'Project Group was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
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

    # Find the project group by ID
    def set_project_group
      @project_group = Hmis::ProjectGroup.find(params[:id])
    end

    # Strong parameters for updating project group
    def project_group_params
      params.require(:project_group).permit(:name, :inclusion_criteria, :exclusion_criteria)
    end
  end
end
