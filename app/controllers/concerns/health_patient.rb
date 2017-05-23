module HealthPatient
  extend ActiveSupport::Concern
  
  included do
    protected def set_client
      @client = GrdaWarehouse::Hud::Client.find(params[:client_id].to_i)
    end
    protected def set_patient
      @patient = Health::Patient.find_by_client_id(params[:client_id].to_i)
    end
  end
end
