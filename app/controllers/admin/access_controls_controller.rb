###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::AccessControlsController < ApplicationController
  include ViewableEntities
  include ArelHelper
  include AuditHistory

  before_action :require_can_edit_users!
  before_action :set_access_control, only: [:edit, :update, :destroy]

  def index
    @access_controls = access_control_scope.
      order(r_t[:name].asc, collection_t[:name].asc).
      filtered(params[:filter])
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
    @pagy, @data = pagy_array(data)
  end

  def export
    respond_to do |format|
      format.csv do
        audit_history = []
        histories.each_with_index do |history, index|
          csv_data = generate_audit_csv(history.version_scope, history, include_headers: index == 0)
          audit_history << csv_data
        end
        send_data audit_history.join, filename: "access-controls-component-history-#{Date.current}.csv"
      end
    end
  end

  private def access_control_scope
    AccessControl.user_managed
  end

  private def filter_params
    params.permit(
      filter: [
        :user_group_id,
        :collection_id,
        :role_id,
        :user_id,
      ],
    )
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

  private def access_controls
    @access_controls ||= AccessControl.all
  end

  private def histories
    @histories ||= [].tap do |histories|
      access_controls.each do |access_control|
        history = Audit::Versions.new(access_control, access_control_component_config)
        histories << history
      end
    end
  end

  private def data
    @data ||= histories.map do |history|
      versions = history.version_scope
      history.wrap_display_versions(versions).map do |version|
        {
          history: history,
          version: version,
        }
      end
    end.flatten(1)
  end
end
