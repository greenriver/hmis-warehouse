# An opportunity is the availability of a resource (housing or other services)

module Hmis::Ce
  class Opportunity < GrdaWarehouseBase
    include AASM

    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :workflow_template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :referrals, class_name: 'Hmis::Ce::Referral', dependent: :restrict_with_exception

    validates :name, presence: true

    aasm column: 'status' do
      state :open, initial: true
      state :closed

      event :close do
        transitions from: :open, to: :closed
      end
    end

    # FIXME: permissions
    scope :viewable_by, ->(_user) { all }

    def requirements
      (requirements_config || []).map { |item| OpenStruct.new(item) }
    end
  end
end
