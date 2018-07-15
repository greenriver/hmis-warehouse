module HealthPatient
  extend ActiveSupport::Concern
  
  included do
    def load_patient_metrics
      @rosters = ::Health::Claims::Roster.all
      
      @view_model = ::Health::Claims::ViewModel.new(@patient, @rosters)
      @patient_summary = @view_model.patient_summary
      @cost_table = @view_model.cost_table
      @km_table = @view_model.key_metrics_table
      @km_rows = [
        [@km_table.patient, 'ho-compare__current-patient'], 
        [@km_table.sdh, 'ho-compare__pilot-average'], 
        [@km_table.variance, 'ho-compare__variance']
      ]
    end

    protected def set_client
      @client = GrdaWarehouse::Hud::Client.find(params[:client_id].to_i)
    end
    protected def set_patient
      @patient = Health::Patient.accessible_by_user(current_user).find_by(client_id: params[:client_id].to_i)
    end

    # For now, all patients are visible to all health users
    # BUT, all patients must have a referral 
    protected def set_hpc_patient
      @patient = Health::Patient.joins(:patient_referral).find_by(client_id: params[:client_id].to_i)
    end
  end
end
