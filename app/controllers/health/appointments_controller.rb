###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class AppointmentsController < HealthController
    # This controller serves both BH CP data and pilot data, so it can't use the BH CP permissions
    include PjaxModalController
    include ClientPathGenerator

    before_action :require_pilot_or_some_client_access!
    before_action :set_client, only: [:index]

    def index
      set_hpc_patient
      set_patient if @patient.blank?
      a_t = Health::Appointment.arel_table
      @appointments = @patient.appointments.order(appointment_time: :desc)
      @upcoming = @appointments.limited.where(a_t[:appointment_time].gt(Time.now)).order(appointment_time: :asc)
      @past = @appointments.where(a_t[:appointment_time].lteq(Time.now)).order(appointment_time: :desc)
      render layout: !request.xhr?
    end

    def upcoming
      set_hpc_patient
      set_patient if @patient.blank?
      start_date = Date.current.to_time
      if params[:end_date].present?
        end_date = begin
                     params[:end_date]&.to_date
                   rescue StandardError
                     start_date + 2.weeks
                   end
      else
        end_date = start_date + 2.weeks
      end
      @appointments = @patient.appointments.
        limited.
        where(appointment_time: (start_date..end_date)).
        order(appointment_time: :asc)
      render layout: !request.xhr?
    end

    private def title_for_show
      "#{@client.name} - Health - Appointments"
    end
  end
end
