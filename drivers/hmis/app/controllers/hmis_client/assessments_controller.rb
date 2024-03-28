###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisClient::AssessmentsController < ApplicationController
  include AjaxModalRails::Controller
  include ClientDependentControllers

  before_action :require_can_view_enrollment_details!
  before_action :client
  before_action :assessment

  # before_action :require_can_manage_client_files!, only: [:update]
  after_action :log_client

  def show
  end

  def client
    @client ||= destination_searchable_client_scope.find(params[:client_id].to_i)
  end

  def assessment
    @assessment ||= @client.hmis_source_custom_assessments.preload(:user, :custom_data_elements, enrollment: :project, form_processor: :definition).
      find(params[:id].to_i)
  end
end
