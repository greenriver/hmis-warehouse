module Health
  class ProblemsController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    
    def index
      @problems = @patient.problems.order(onset_date: :desc)
      
      render layout: !request.xhr?
    end

  end
end