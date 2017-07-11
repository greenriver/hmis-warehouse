module Admin::Health
  class PatientsController < ApplicationController
    before_action :require_can_administer_health!
    before_filter :set_patients, only: [:index, :update]

    def index
      sort = params.permit(:sort, :direction)
      @column = sort[:sort]&.to_sym || patient_source.default_sort_column
      @direction = sort[:direction]&.to_sym || patient_source.default_sort_direction
      @patients = @patients.order(
        patient_source.column_from_sort(
          column: @column,
          direction: @direction
        ).to_sql
      )
      if params[:q].present?
        @patients = @patients.text_search(params[:q])
      end
      @patients = @patients.page(params[:page].to_i).per(5)
    end

    def update
      @patients = @patients.page(params[:page].to_i).per(5)
      error = false
      patients_params.each do |patient_id, client|
        begin
          patient_source.transaction do
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
      @patients = patient_scope.
        includes(:client)
    end

    def patient_scope
      patient_source.all
    end

    def patient_source
      ::Health::Patient
    end
  end
end