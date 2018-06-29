module Window::Health
  class PatientTeamMembersController < IndividualPatientController

    before_action :set_client

    include WindowClientPathGenerator

    def index
      @teams = @client.patient.teams
    end

  end
end