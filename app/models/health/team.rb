module Health
  class Team < HealthBase
    # TODO remove me
    has_paper_trail
    acts_as_paranoid
    has_many :members, class_name: Health::Team::Member.name
    # has_one :pcp_designee, class_name: Health::Team::PcpDesignee.name
    belongs_to :patient
    belongs_to :editor, class_name: User.name, foreign_key: :user_id

    accepts_nested_attributes_for :members, allow_destroy: true

    # Used for select options
    def available_members
      # members.map do |member|
      #   [
      #     member.full_name, member.id
      #   ]
      # end
      # PT story #158636393 taken off the of the careplan and added to the patient
      # adding this here in case I missed any spots
      patient.available_team_members
    end

  end
end