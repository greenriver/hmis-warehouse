module Admin::Health
  class PatientsController < ApplicationController
    before_action :require_can_administer_health!
    before_filter :set_patients, only: [:index, :update]

    def index
      @patients = @patients.page(params[:page].to_i).per(50)
    end

    def update
      @patients = @patients.page(params[:page].to_i).per(50)
      error = false
      patients_params.each do |patient_id, client|
        begin
          ::Health::Patient.transaction do
            patient = ::Health::Patient.find(patient_id.to_i)
            if client[:client_id].present? && client[:client_id].to_i != 0
              patient.update(client_id: client[:client_id].to_i)
            else
              patient.update(client_id: nil)
            end
          end
        rescue ActiveRecord::ActiveRecordError => e
          flash[:error] = 'Unable to update patients'
          error = true
          render action: :index
        end
      end
      redirect_to action: :index if ! error
    end

    def patients_params
      params.require(:patients)
    end

    def set_patients
      @patients = ::Health::Patient.all.order(last_name: :asc, first_name: :asc)
    end
  end
end