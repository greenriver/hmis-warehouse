# frozen_string_literal: true

# An opportunity is the availability of a unit (housing or other services)

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
    has_many :categorizations, class_name: 'Hmis::Ce::OpportunityCategorization', foreign_key: :opportunity_id, dependent: :destroy
    has_many :categories, through: :categorizations
    belongs_to :unit, class_name: 'Hmis::Unit', foreign_key: :unit_id
    has_one :active_referral, -> { active }, class_name: 'Hmis::Ce::Referral', foreign_key: :opportunity_id
    has_one :active_or_accepted_referral, -> { active_or_accepted }, class_name: 'Hmis::Ce::Referral', foreign_key: :opportunity_id
    has_many :swimlanes, through: :workflow_template, class_name: 'Hmis::WorkflowDefinition::Swimlane'

    validates :name, presence: true
    validate :unique_opportunity_per_unit
    validate :consistent_data_source

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
      joins(:project).merge(Hmis::Hud::Project.viewable_by(user).with_access(user, :can_view_units))
    end

    scope :active, -> { where.not(status: 'closed') }

    # TODO(#7537) - implement "available_on_date". For now, return all
    scope :available_on_date, ->(_date) { all }

    # Which opportunities are available for a given client
    scope :for_client, ->(client) {
      eligible_pool_ids = client.destination_client&.as_warehouse&.ce_match_candidates&.select(:candidate_pool_id)
      return Hmis::Ce::Opportunity.none if eligible_pool_ids.blank?

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

    SORT_OPTIONS = [:date_available_earliest_first, :date_available_latest_first].freeze

    SORT_OPTION_DESCRIPTIONS = {
      date_available_earliest_first: 'Date Available, earliest first',
      date_available_latest_first: 'Date Available, latest first',
    }.freeze

    def self.sort_by_option(option)
      case option
      when :date_available_earliest_first
        # TODO(#7537) - implement "available_on_date" and incorporate that logic here.
        order(created_at: :asc)
      when :date_available_latest_first
        order(created_at: :desc)
      else
        raise NotImplementedError
      end
    end

    def self.apply_filters(input)
      Hmis::Filter::CeOpportunityFilter.new(input).filter_scope(self)
    end

    def self.active_referral_ids_for_units(units)
      r_t = Hmis::Ce::Referral.arel_table
      joins(:active_referral).where(unit_id: units.map(&:id)).pluck(r_t[:id])
    end

    def active?
      !closed?
    end

    private

    def unique_opportunity_per_unit
      return if status.to_sym == :closed || unit.nil?

      # This validator expects that unit's opportunities are preloaded, to avoid n+1 on save
      conflicting_opportunity_exists = unit.opportunities.to_a.select do |existing_opp|
        existing_opp.status.to_sym != :closed && existing_opp.id != id
      end.any?
      return unless conflicting_opportunity_exists

      errors.add(:unit, 'can only have one open or locked opportunity')
    end

    def consistent_data_source
      return if project.data_source == workflow_template.data_source

      errors.add(:project, 'must be in same data source as workflow template')
    end
  end
end
