###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisClient::ServicesController < ApplicationController
  include AjaxModalRails::Controller
  include ClientDependentControllers
  include ClientEnrollmentVisibility

  before_action :require_can_view_enrollment_details!
  before_action :client
  before_action :service

  # before_action :require_can_manage_client_files!, only: [:update]
  after_action :log_client

  def show
  end

  def client
    @client ||= destination_visible_client_scope.find(params[:client_id].to_i)
  end

  def service
    @service ||= @client.custom_services.
      where(visible_enrollment_condition).
      preload(:user, :custom_data_elements, enrollment: :project, form_processor: :definition).
      find(params[:id].to_i)
  end
end
