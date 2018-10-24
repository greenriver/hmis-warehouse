module Window::Health
  class MetricsController < HealthController

    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    include ActionView::Helpers::NumberHelper

    helper HealthOverviewHelper
    
    def index
      load_patient_metrics

      @scrolspy = true
      
      render layout: !request.xhr?      
    end

    protected def title_for_show
      "#{@client.name} - Health - Metrics"
    end
  end
end