# An opportunity is the availability of a resource (housing or other services)

module Hmis::Ce
  class Opportunity < GrdaWarehouseBase
    include AASM

    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :workflow_template,
      -> { published },
      foreign_key: 'workflow_template_identifier',
      primary_key: 'identifier',
      class_name: 'Hmis::WorkflowDefinition::Template'

    has_many :referrals, class_name: 'Hmis::Ce::Referral', dependent: :restrict_with_exception

    validates :name, presence: true

    aasm column: 'status' do
      state :open, initial: true
      state :locked
      state :closed

      event :close do
        transitions from: [:open, :locked], to: :closed
      end
      event :lock do
        transitions from: :open, to: :locked
      end
      event :unlock do
        transitions from: :locked, to: :open
      end
    end

    # FIXME: permissions
    scope :viewable_by, ->(_user) { all }

    def requirements
      (requirements_config || []).map { |item| OpenStruct.new(item) }
    end
  end
end
