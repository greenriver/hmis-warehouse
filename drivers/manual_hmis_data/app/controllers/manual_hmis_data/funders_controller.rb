###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ManualHmisData
  class FundersController < ApplicationController
    before_action :require_can_view_projects!
    before_action :require_can_edit_projects!, only: [:new, :create, :edit, :update, :destroy]
    before_action :set_funder, only: [:update, :edit, :destroy]
    before_action :set_fields, only: [:new, :edit]
    before_action :set_project, only: [:create]

    include ArelHelper
    include AjaxModalRails::Controller

    def new
    end

    def create
      funder = @project.funders.create(
        **funder_params,
        manual_entry: true,
        ProjectID: @project.ProjectID,
        DateCreated: Time.current,
        DateUpdated: Time.current,
        UserID: current_user.email,
      )
      funder.FunderID = "m-#{funder.id}"
      funder.ExportID = "m-#{funder.id}"
      funder.save
      respond_with(@project, location: project_path(@project))
    end

    def edit
    end

    def update
      @funder.update(funder_params)
      respond_with(@funder, location: project_path(@funder.project))
    end

    def destroy
      @funder.destroy
      respond_with(@funder, location: project_path(@funder.project))
    end

    private def funder_params
      params.require(:funder).permit(
        *funder_source.hmis_structure.keys,
      )
    end

    private def funder_scope
      funder_source.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    private def funder_source
      GrdaWarehouse::Hud::Funder
    end

    private def set_funder
      @funder = funder_scope.find(params[:id].to_i)
    end

    private def set_project
      @project = GrdaWarehouse::Hud::Project.find(params[:project_id].to_i)
    end

    private def set_fields
      @fields = processed_form_fields
    end

    private def base_fields
      funder_source.hmis_structure
    end

    private def field_exclusions
      [
        :FunderID,
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
        Funder: {
          type: :select_two,
          collection: HUD.funding_sources.invert,
        },
        StartDate: {
          type: :date_picker,
        },
        EndDate: {
          type: :date_picker,
        },
      }
    end

    def flash_interpolation_options
      { resource_name: 'Funder' }
    end
  end
end
