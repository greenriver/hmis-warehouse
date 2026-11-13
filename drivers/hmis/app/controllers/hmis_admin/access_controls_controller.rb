###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisAdmin::AccessControlsController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled
  include HmisAccessControlAuditData
  include AccessControlEntityFilterOptions
  extend BackgroundRenderAction

  before_action :require_hmis_admin_access!
  before_action :set_access_control, only: [:edit, :update, :destroy]

  background_render_action(:render_audits, ::BackgroundRender::HmisAccessControlsAuditsJob) do
    {
      user_id: current_user.id,
    }
  end

  def index
    @access_controls = access_control_scope.
      ordered.
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
    respond_with(@access_control, location: hmis_admin_access_controls_path)
  end

  def edit
  end

  def update
    @access_control.update(access_control_params)
    @access_control.save

    redirect_to({ action: :index }, notice: 'Access Control List updated.')
  end

  def destroy
    @access_control.destroy
    redirect_to({ action: :index }, notice: 'Access Control List removed.')
  end

  def audits
    @excel_export = GrdaWarehouse::DocumentExports::HmisAccessControlsAuditExport.new
    # Processing is backgrounded unless render_inline is set to 1
    @data = data if params[:render_inline] == '1'
  end

  private def access_control_scope
    Hmis::AccessControl
  end

  private def filter_params
    params.permit(
      filter: [
        :user_group_id,
        :user_id,
        :role_id,
        :access_group_id,
        :data_source_id,
        :organization_id,
        :project_id,
        :coc_code,
      ],
    )
  end

  private def filter_data_source_scope
    GrdaWarehouse::DataSource.hmis
  end

  private def access_control_params
    params.require(:access_control).permit(
      :role_id,
      :access_group_id,
      :user_group_id,
    )
  end

  private def set_access_control
    @access_control = access_control_scope.find(params[:id].to_i)
    @access_control.define_singleton_method(:name) { "Access Control List #{id}" }
  end

  private def data
    @data ||= begin
      histories = build_histories
      build_data(histories)
    end
  end
end
