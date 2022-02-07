###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ManualHmisData
  class ProjectCocsController < ApplicationController
    before_action :require_can_view_projects!
    before_action :require_can_edit_projects!, only: [:new, :create, :edit, :update, :destroy]
    before_action :set_project_coc, only: [:update, :edit, :destroy]
    before_action :set_fields, only: [:new, :edit]
    before_action :set_project, only: [:create]

    include ArelHelper
    include AjaxModalRails::Controller

    def new
    end

    def create
      project_coc = @project.project_cocs.create(
        **project_coc_params,
        manual_entry: true,
        ProjectID: @project.ProjectID,
        DateCreated: Time.current,
        DateUpdated: Time.current,
        UserID: current_user.email,
      )
      project_coc.ProjectCoCID = "m-#{project_coc.id}"
      project_coc.ExportID = "m-#{project_coc.id}"
      project_coc.save
      respond_with(@project, location: project_path(@project))
    end

    def edit
    end

    def update
      @project_coc.update(project_coc_params)
      respond_with(@project_coc, location: project_path(@project_coc.project))
    end

    def destroy
      @project_coc.destroy
      respond_with(@project_coc, location: project_path(@project_coc.project))
    end

    private def project_coc_params
      params.require(:project_coc).permit(
        *project_coc_source.hmis_structure.keys,
      )
    end

    private def project_coc_scope
      project_coc_source.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    private def project_coc_source
      GrdaWarehouse::Hud::ProjectCoc
    end

    private def set_project_coc
      @project_coc = project_coc_scope.find(params[:id].to_i)
    end

    private def set_project
      @project = GrdaWarehouse::Hud::Project.find(params[:project_id].to_i)
    end

    private def set_fields
      @fields = processed_form_fields
    end

    private def base_fields
      project_coc_source.hmis_structure
    end

    private def field_exclusions
      [
        :ProjectCoCID,
        :ProjectID,
        :DateCreated,
        :DateUpdated,
        :DateDeleted,
        :UserID,
        :ExportID,
      ]
    end

    private def processed_form_fields
      base_fields.
        reject { |k, _v| field_exclusions.include?(k) }.
        map do |k, v|
          html_input = {}
          html_input[:maxlength] = v[:limit] if v[:limit].present?
          [k, { **v, html_input: html_input }]
        end.to_h.
        merge(field_overrides) do |_k, oldval, newval|
          oldval.merge(newval)
        end
    end

    private def field_overrides
      {
        GeographyType: {
          type: :select_two,
          collection: HUD.geography_types.invert,
        },
      }
    end

    def flash_interpolation_options
      { resource_name: 'Project CoC Record' }
    end
  end
end
