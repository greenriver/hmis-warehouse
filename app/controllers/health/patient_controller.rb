module Health
  class PatientController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    include PjaxModalController
    include HealthPatient
    
    def index
      
      
    end


    protected def set_client
      @client = GrdaWarehouse::Hud::Client.find(params[:client_id].to_i)
    end
  end
end