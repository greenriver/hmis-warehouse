###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::AccessControlsController < ApplicationController
  include ViewableEntities
  include ArelHelper
  include AccessControlAuditData
  include AccessControlEntityFilterOptions
  extend BackgroundRenderAction

  AUDIT_ACTIONS = [:audits, :render_audits].freeze

  before_action :require_can_edit_users!, except: AUDIT_ACTIONS
  before_action :require_can_audit_users!, only: AUDIT_ACTIONS
  before_action :set_access_control, only: [:edit, :update, :destroy]

  background_render_action(:render_audits, ::BackgroundRender::AccessControlsAuditsJob) do
    {
      user_id: current_user.id,
    }
  end

  def index
    @access_controls = access_control_scope.
      order(r_t[:name].asc, collection_t[:name].asc).
      filtered(filter_params[:filter])
    @pagy, @access_controls = pagy(@access_controls)
    @active_filter = filter_params[:filter]&.values&.any?(&:present?)
  end

  def new
    @access_control = access_control_scope.new
  end

  def create
    @access_control = access_control_scope.new
    @access_control.update(access_control_params)
    @access_control.save
    respond_with(@access_control, location: admin_access_controls_path)
  end

  def edit
  end

  def update
    @access_control.update(access_control_params)
    @access_control.save

    respond_with(@access_control, location: admin_access_controls_path)
  end

  def destroy
    @access_control.destroy
    respond_with(@access_control, location: admin_access_controls_path)
  end

  def assign
    # TODO: this isn't built
    flash[:notice] = "TODO #{user.name} was added to selected Access Controls"
    redirect_to action: :index
  end

  def audits
    @excel_export = GrdaWarehouse::DocumentExports::AccessControlsAuditExport.new
    # Processing is backgrounded unless render_inline is set to 1
    data if params[:render_inline] == '1'
  end

  private def access_control_scope
    AccessControl.user_managed
  end

  private def filter_params
    params.permit(
      filter: [
        :user_group_id,
        :user_id,
        :role_id,
        :collection_id,
        :data_source_id,
        :organization_id,
        :project_id,
        :coc_code,
      ],
    )
  end

  private def filter_data_source_scope
    GrdaWarehouse::DataSource.source
  end

  # Warehouse collections can list CoC codes that no project uses
  private def coc_code_filter_options
    collection_coc_codes = GrdaWarehouse::Lookups::CocCode.where(
      id: GrdaWarehouse::GroupViewableEntity.using_acls.where(entity_type: GrdaWarehouse::Lookups::CocCode.sti_name).select(:entity_id),
    ).pluck(:coc_code)
    (super + collection_coc_codes).uniq.sort
  end

  private def access_control_params
    params.require(:access_control).permit(
      :role_id,
      :collection_id,
      :user_group_id,
    )
  end

  private def set_access_control
    @access_control = access_control_scope.find(params[:id].to_i)
  end

  private def data
    @data ||= begin
      histories = build_histories(current_user)
      build_data(histories)
    end
  end
end
