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
    has_one :active_or_accepted_referral, -> { active_or_accepted }, class_name: 'Hmis::Ce::Referral', foreign_key: :opportunity_id
    has_many :swimlanes, through: :workflow_template, class_name: 'Hmis::WorkflowDefinition::Swimlane'

    validates :name, presence: true
    validate :unique_opportunity_per_unit

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

    scope :viewable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.with_access(user, :can_view_units))
    end

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

    scope :actives_first, -> {
      o_t = Hmis::Ce::Opportunity.arel_table
      order(
        o_t[:status].when('closed').then(1).else(0).asc,
        o_t[:created_at].desc,
        o_t[:id].desc,
      )
    }

    def active?
      !closed?
    end

    private

    def unique_opportunity_per_unit
      return if status.to_sym == :closed || owner.nil?

      # This validator expects that owner's opportunities are preloaded, to avoid n+1 on save
      conflicting_opportunity_exists = owner.opportunities.to_a.select do |existing_opp|
        existing_opp.status.to_sym != :closed && existing_opp.id != id
      end.any?
      return unless conflicting_opportunity_exists

      errors.add(:owner, 'can only have one opportunity')
    end
  end
end
