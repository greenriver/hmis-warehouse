###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
        [@km_table.variance, 'ho-compare__variance'],
      ]
    end

    protected def set_client
      # Do we have this client?
      # If not, attempt to redirect to the most recent version
      # If there's not merge path, just force an active record not found
      if client_scope.where(id: params[:client_id].to_i).exists?
        @client = client_scope.find(params[:client_id].to_i)
      else
        client_id = GrdaWarehouse::ClientMergeHistory.new.current_destination params[:client_id].to_i
        if client_id
          redirect_to controller: controller_name, action: action_name, client_id: client_id
          # client_scope.find(client_id)
        else
          @client = client_scope.find(params[:client_id].to_i)
        end
      end
    end

    protected def client_scope
      GrdaWarehouse::Hud::Client.destination
    end

    # Note: use set_hpc_patient instead.
    # This bypasses the filter for disenrolled patients. Only used by pilot program.
    protected def set_patient
      @patient = Health::Patient.accessible_by_user(current_user).find_by(client_id: params[:client_id].to_i)
    end

    protected def set_hpc_patient
      @patient = Health::Patient.viewable_by_user(current_user).find_by(client_id: params[:client_id].to_i)

      not_authorized! unless @patient.present?
    end
  end
end
