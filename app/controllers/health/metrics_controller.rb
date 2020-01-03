###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class MetricsController < HealthController
    include PjaxModalController
    include ClientPathGenerator
    include ActionView::Helpers::NumberHelper

    helper HealthOverviewHelper

    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]

    def index
      load_patient_metrics

      render layout: !request.xhr?
    end

    protected def title_for_show
      "#{@client.name} - Health - Metrics"
    end
  end
end
