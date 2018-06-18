module Window::Health
  class AppointmentsController < IndividualPatientController

    before_action :set_client, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    def index
      set_hpc_patient
      if @patient.blank?
        set_patient
      end
      a_t = Health::Appointment.arel_table
      @appointments = @patient.appointments.order(appointment_time: :desc)
      @upcoming = @appointments.limited.where(a_t[:appointment_time].gt(Time.now)).order(appointment_time: :asc)
      @past = @appointments.where(a_t[:appointment_time].lteq(Time.now)).order(appointment_time: :desc)
      render layout: !request.xhr?
    end

  end
end