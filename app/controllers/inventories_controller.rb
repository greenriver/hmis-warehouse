###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class InventoriesController < ApplicationController
  before_action :require_can_view_projects!
  before_action :require_can_edit_projects!, only: [:edit, :update]
  before_action :set_inventory, only: [:show, :update, :edit]
  before_action :set_project, only: [:edit, :update]

  include ArelHelper
  include AjaxModalRails::Controller

  def edit
  end

  def update
    @inventory.update(inventory_params)
    respond_with(@inventory, location: project_path(@project))
  end

  private def inventory_params
    params.require(:inventory).permit(
      :coc_code_override,
      :inventory_start_date_override,
      :inventory_end_date_override,
    )
  end

  private def inventory_scope
    inventory_source.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
  end

  private def inventory_source
    GrdaWarehouse::Hud::Inventory
  end

  private def set_inventory
    @inventory = inventory_scope.find(params[:id].to_i)
  end

  private def set_project
    @project = @inventory.project
  end

  def flash_interpolation_options
    { resource_name: 'Inventory' }
  end
end
