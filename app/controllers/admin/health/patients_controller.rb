###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class PatientsController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_administer_health!
    before_action :set_patients, only: [:index, :update]

    def index
      sort = params.permit(:sort, :direction)
      @column = sort[:sort]&.to_sym || patient_source.default_sort_column
      @direction = sort[:direction]&.to_sym || patient_source.default_sort_direction
      @patients = @patients.order(
        patient_source.column_from_sort(
          column: @column,
          direction: @direction,
        ).to_sql,
      )
      @patients = @patients.text_search(params[:q]) if params[:q].present?
      @patients = @patients.page(params[:page].to_i).per(50)
    end

    def update
      @patients = @patients.page(params[:page].to_i).per(50)
      error = false
      patients_params.each do |patient_id, client|
        patient_source.transaction do
          patient = ::Health::Patient.find(patient_id.to_i)
          if client[:client_id].present? && client[:client_id].to_i != 0
            patient.update(client_id: client[:client_id].to_i)
          else
            patient.update(client_id: nil)
          end
        end
      rescue ActiveRecord::ActiveRecordError
        flash[:error] = 'Unable to update patients'
        error = true
        render action: :index
      end
      redirect_to action: :index unless error
    end

    def patients_params
      params.require(:patients)
    end

    def set_patients
      @patients = patient_scope.
        includes(:client)
    end

    def patient_scope
      patient_source.pilot
    end

    def patient_source
      ::Health::Patient
    end
  end
end
