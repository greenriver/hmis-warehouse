###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health::Pilot
  class MetricsController < HealthController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include ActionView::Helpers::NumberHelper

    helper HealthOverviewHelper

    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]

    def index
      load_patient_metrics

      render layout: !request.xhr?
    end
  end
end
