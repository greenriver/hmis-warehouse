###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class HudAssessmentsController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    before_action :require_can_view_enrollment_details_tab!
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
      @assessment ||= @client.source_assessments.preload(:assessment_questions, :assessment_results, enrollment: :project).
        find(params[:id].to_i)
    end
  end
end
