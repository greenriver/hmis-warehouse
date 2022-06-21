###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ManualHmisData
  class InventoriesController < ApplicationController
    before_action :require_can_view_projects!
    before_action :require_can_edit_projects!, only: [:new, :create, :edit, :update, :destroy]
    before_action :set_inventory, only: [:update, :edit, :destroy]
    before_action :set_fields, only: [:new, :edit]
    before_action :set_project, only: [:create]

    include ArelHelper
    include AjaxModalRails::Controller

    def new
    end

    def create
      inventory = @project.inventories.create(
        **inventory_params,
        manual_entry: true,
        ProjectID: @project.ProjectID,
        DateCreated: Time.current,
        DateUpdated: Time.current,
        UserID: current_user.email,
      )
      inventory.InventoryID = "m-#{inventory.id}"
      inventory.ExportID = "m-#{inventory.id}"
      inventory.save
      respond_with(@project, location: project_path(@project))
    end

    def edit
    end

    def update
      @inventory.update(inventory_params)
      respond_with(@inventory, location: project_path(@inventory.project))
    end

    def destroy
      @inventory.destroy
      respond_with(@inventory, location: project_path(@inventory.project))
    end

    private def inventory_params
      params.require(:inventory).permit(
        *inventory_source.hmis_structure.keys,
      )
    end

    private def inventory_scope
      inventory_source.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user, non_confidential_scope_limiter: :all))
    end

    private def inventory_source
      GrdaWarehouse::Hud::Inventory
    end

    private def set_inventory
      @inventory = inventory_scope.find(params[:id].to_i)
    end

    private def set_project
      @project = GrdaWarehouse::Hud::Project.find(params[:project_id].to_i)
    end

    private def set_fields
      @fields = processed_form_fields
    end

    private def base_fields
      inventory_source.hmis_structure
    end

    private def field_exclusions
      [
        :InventoryID,
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
        HouseholdType: {
          type: :select_two,
          collection: GrdaWarehouse::Hud::Inventory.household_types,
        },
        Availability: {
          type: :select_two,
          collection: HUD.availabilities.invert,
        },
        CoCCode: {
          type: :select_two,
          collection: GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode),
        },
        InventoryStartDate: {
          type: :date_picker,
        },
        InventoryEndDate: {
          type: :date_picker,
        },
        ESBedType: {
          type: :select_two,
          collection: HUD.bed_types.invert,
        },
      }
    end

    def flash_interpolation_options
      { resource_name: 'Inventory' }
    end
  end
end
