module HealthTeamMember
  extend ActiveSupport::Concern

  def new
    @member = Health::Team::Member.new
  end

  def create
    type = team_member_params[:type]
    klass = type.constantize if Health::Team::Member.available_types.map(&:to_s).include?(type)
    opts = team_member_params.merge({
      user_id: current_user.id,
      patient_id: @client.patient.id
    })
    raise 'Member type not found' unless klass.present?
    if ! request.xhr?
      @member = klass.create(opts)
      respond_with(@member, location: after_path)
      return
    else
      @new_member = klass.create(opts)
    end
  end

  def edit
    @member = Health::Team::Member.find(params[:id])
  end

  def update
    @member = Health::Team::Member.find(params[:id])
    @member.update_attributes(team_member_params)
    if !request.xhr?
      respond_with(@member, location: after_path)
    end
  end

  def destroy
    @member = Health::Team::Member.find(params[:id])
    if @member.in_use?
      @member.remove_from_careplans
      @member.remove_from_goals
    end
    @member.update(user_id: current_user.id)
    @member.destroy!

    if !request.xhr?
      respond_with(@member, location: after_path)
    end
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

end