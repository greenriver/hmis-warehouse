module Window::Health::Careplan::Team
  class MembersController < HealthController
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :ensure_patient_team
    before_action :set_team_member, only: [:destroy]
    before_action :set_deleted_team_member, only: [:restore]

    include PjaxModalController  

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
      begin
        raise 'Member type not found' unless klass.present?
        new_member = klass.create!(opts)
        @team.update(user_id: current_user.id)
        flash[:notice] = "Added #{new_member.full_name} to team"
        redirect_to action: :index
      rescue Exception => e
        @member.validate
        flash[:error] = "Failed to add Team Member #{e}"
        render action: :index
      end
    end

    def destroy
      begin
        @member.update(user_id: current_user.id)
        @member.destroy!
        @team.update(user_id: current_user.id)
        flash[:notice] = "Removed #{@member.full_name} from team"
      rescue Exception => e
        flash[:error] = "Failed to delete Team Member"
      end
      redirect_to action: :index
    end

    def team_member_params
      params.require(:member).permit(
        :first_name,
        :last_name,
        :email,
        :organization,
        :title,
        :type
      )
    end
    
    private def set_team_member
      @member = ::Health::Team::Member.find(params[:id].to_i)
    end

    private def set_deleted_team_member
      @member = ::Health::Team::Member.with_deleted.find(params[:member_id].to_i)
    end

    private def ensure_patient_team
      @patient.create_team unless @patient.team.present?
      @team = @patient.team
    end
  end
end