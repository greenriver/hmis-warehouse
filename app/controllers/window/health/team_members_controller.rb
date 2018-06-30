module Window::Health
  class TeamMembersController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_deleted_team_member, only: [:restore]

    include PjaxModalController
    include WindowClientPathGenerator
    include HealthTeamMember

    def index
      @member = Health::Team::Member.new

    end

    def previous

    end

    def restore
      begin
        @member.restore!
        @member.update(user_id: current_user.id)
        @team.update(user_id: current_user.id)
      rescue Exception => e
        flash[:error] = "Unable to restore team member: #{e}"
      end
      redirect_to action: :index
    end

    def after_path
      polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
    end

    def team_member_form_path
      if @member.new_record?
        polymorphic_path(careplan_path_generator + [:team, :members])
      else
        polymorphic_path(careplan_path_generator + [:team, :member], id: @member.id)
      end
    end
    helper_method :team_member_form_path

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end

    private def set_deleted_team_member
      @member = ::Health::Team::Member.with_deleted.find(params[:member_id].to_i)
    end

    def flash_interpolation_options
      { resource_name: 'Team Member' }
    end
  end
end