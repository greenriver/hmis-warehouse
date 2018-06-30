module Window::Health
  class PatientTeamMembersController < IndividualPatientController

    before_action :set_client

    include PjaxModalController
    include WindowClientPathGenerator
    include HealthTeamMember

    def index
      @team_members = @client.patient.team_members
    end

    def after_path
      polymorphic_path(team_members_path_generator)
    end

    def team_member_form_path
      if @member.new_record?
        polymorphic_path(team_members_path_generator)
      else
        polymorphic_path(team_member_path_generator, id: @member.id)
      end
    end
    helper_method :team_member_form_path

  end
end