# frozen_string_literal: true

# An opportunity is the availability of a resource (housing or other services)

module Hmis::Ce
  class Opportunity < GrdaWarehouseBase
    include SimpleStateMachine

    belongs_to :project, class_name: 'Hmis::Hud::Project', inverse_of: :ce_opportunities
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool', optional: true
    belongs_to :workflow_template,
               -> { published },
               foreign_key: 'workflow_template_identifier',
               primary_key: 'identifier',
               class_name: 'Hmis::WorkflowDefinition::Template'

    has_many :referrals, class_name: 'Hmis::Ce::Referral', dependent: :restrict_with_exception
    has_many :categorizations, class_name: 'Hmis::Ce::OpportunityCategorization', foreign_key: :opportunity_id
    has_many :categories, through: :categorizations
    belongs_to :owner, polymorphic: true, optional: true # Hmis::Unit, ...
    has_one :active_referral, -> { active }, class_name: 'Hmis::Ce::Referral', foreign_key: :opportunity_id

    validates :name, presence: true

    state_machine_config column: 'status' do
      state :open, initial: true
      state :locked
      state :closed

      event :close do
        transitions from: [:open, :locked], to: :closed
      end
      # lock the opportunity to prevent multiple simultaneous referrals
      event :reserve do
        transitions from: :open, to: :locked
      end
      event :release do
        transitions from: :locked, to: :open
      end
    end

    # TODO(#7395): permissions
    scope :viewable_by, ->(_user) { all }

    scope :active, -> { where.not(status: 'closed') }

    # Which opportunities are available for a given client
    scope :for_client, ->(client) {
      eligible_pool_ids = client.ce_match_candidates.select(:candidate_pool_id)
      scope = self.open.where(candidate_pool_id: eligible_pool_ids)

      exclude_ids = []
      # exclude opportunities where the client has already been referred
      exclude_ids += client.ce_referrals.distinct.pluck(:opportunity_id)

      # exclude opportunities with overlapping categories from this client's active referrals
      active_category_ids = Hmis::Ce::OpportunityCategory.
        joins(:opportunities).
        where(ce_opportunities: { id: client.ce_referrals.active.select(:opportunity_id) }).
        pluck(:id)
      exclude_ids += Hmis::Ce::Opportunity.joins(:categories).
        where(ce_opportunity_categories: { id: active_category_ids }).
        pluck(:id)

      scope = scope.where.not(id: exclude_ids.sort.uniq)
      scope
    }

    def active?
      status.to_sym != :closed
    end
  end
end
