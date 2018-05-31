module Window::Health
  class TeamMembersController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :ensure_patient_team
    before_action :set_team_member, only: [:destroy]
    before_action :set_deleted_team_member, only: [:restore]

    include PjaxModalController
    include WindowClientPathGenerator
    def index
      @member = Health::Team::Member.new

    end

    def new
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

    def create
      type = team_member_params[:type]
      @member = Health::Team::Member.new(team_member_params)
      klass = type.constantize if Health::Team::Member.available_types.map(&:to_s).include?(type)
      opts = team_member_params.merge({
        team_id: @team.id,
        user_id: current_user.id
      })
      raise 'Member type not found' unless klass.present?
      if ! request.xhr?
        @member = klass.create(opts)
        respond_with(@member, location: polymorphic_path([:edit] + careplan_path_generator, id: @careplan))
        return
      else
        @new_member = klass.create(opts)
      end
    end

    def destroy
      @member.update(user_id: current_user.id)
      @member.destroy!
      @team.update(user_id: current_user.id)
    end

    def team_member_params
      params.require(:member).permit(
        :first_name,
        :last_name,
        :email,
        :organization,
        :title,
        :type,
        :phone
      )
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end
    
    private def set_team_member
      @member = ::Health::Team::Member.find(params[:id].to_i)
    end

    private def set_deleted_team_member
      @member = ::Health::Team::Member.with_deleted.find(params[:member_id].to_i)
    end

    private def ensure_patient_team
      @careplan.create_team unless @careplan.team.present?
      @team = @careplan.team
    end

    def flash_interpolation_options
      { resource_name: 'Team Member' }
    end
  end
end