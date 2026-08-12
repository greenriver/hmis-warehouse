###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This controller is used specifcally for limited client dashboards when the client dashboard config is set to boston.
# It exposes full assessment details for Pathways and Transfer assessments only.
module Clients
  class CoordinatedEntryHudAssessmentsController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller

    before_action :client
    before_action :assessment
    before_action :require_can_view_coordinated_entry_assessment!

    def show
      log_client
    end

    def client
      @client ||= GrdaWarehouse::Hud::Client.destination_visible_to(current_user).find(params[:client_id].to_i)
    end

    def assessment
      @assessment ||= @client.source_assessments.preload(:assessment_questions, :assessment_results, enrollment: :project).
        find(params[:id].to_i)
    end

    private def require_can_view_coordinated_entry_assessment!
      allowed = GrdaWarehouse::Config.get(:client_dashboard).to_s == 'boston' &&
        current_user&.can_view_limited_client_dashboard? &&
        @assessment.pathways_or_transfer?
      not_authorized! unless allowed
    end
  end
end
