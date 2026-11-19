###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class OrganizationsController < ApplicationControllerV2
  include ArelHelper
  # viewable_by includes organizations reached only through one of their projects, so the
  # policy decides whether the user may change the organization itself.
  before_action :set_organization, only: [:destroy, :edit, :update]
  authorize_with(only: :destroy) { organization_policy.can_delete? }
  authorize_with(only: [:edit, :update]) { organization_policy.can_edit? }

  helper_method def organization_policy
    current_user.policy_for(@organization)
  end

  def destroy
    name = @organization.OrganizationName
    DeleteItemJob.perform_later(item_id: @organization.id, item_class: @organization.class.name)
    flash[:notice] = "Organization: #{name} was successfully queued for removal.  Please check back in a few minutes."
    respond_with @organization, location: data_source_path(@organization.data_source, coc_code: params[:coc_code])
  end

  def edit
    # for breadcrumbs
    @entity = @organization
  end

  def update
    @organization.update(organization_params)
    respond_with @organization, location: data_source_path(@organization.data_source, coc_code: params[:coc_code])
  end

  private def organization_params
    params.require(:organization).permit(
      :confidential,
    )
  end

  private def organization_scope
    organization_source.viewable_by current_user
  end

  private def organization_source
    GrdaWarehouse::Hud::Organization
  end

  private def set_organization
    @organization = organization_scope.find(params[:id].to_i)
  end

  def flash_interpolation_options
    { resource_name: 'Organization' }
  end
end
