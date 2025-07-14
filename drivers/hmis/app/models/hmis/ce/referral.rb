###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A referral of an individual client to an opportunity
module Hmis::Ce
  class Referral < GrdaWarehouseBase
    include SimpleStateMachine

    has_paper_trail

    belongs_to :opportunity, class_name: 'Hmis::Ce::Opportunity'
    has_one :data_source, through: :opportunity, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :workflow_instance, class_name: 'Hmis::WorkflowExecution::Instance'
    has_one :workflow_template, class_name: 'Hmis::WorkflowDefinition::Template', through: :workflow_instance, source: :template
    has_many :notes, class_name: 'Hmis::Ce::ReferralNote', dependent: :destroy
    has_many :participants, class_name: 'Hmis::Ce::ReferralParticipant', dependent: :destroy
    belongs_to :client, class_name: 'Hmis::Hud::Client'
    belongs_to :referred_by, class_name: 'Hmis::User'
    belongs_to :target_enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
    belongs_to :source_enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
    has_one :target_project, class_name: 'Hmis::Hud::Project', through: :opportunity, source: :project
    has_many :swimlanes, through: :workflow_instance, class_name: 'Hmis::WorkflowDefinition::Swimlane'
    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance
    has_many :audit_events, class_name: 'Hmis::WorkflowExecution::AuditEvent', through: :workflow_instance
    belongs_to :custom_status, class_name: 'Hmis::Ce::CustomReferralStatus', foreign_key: :custom_referral_status_id, optional: true

    has_many :current_steps, -> { preload(:node) }, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance, source: :open_steps

    scope :viewable_by, ->(user) do
      # What makes a referral viewable by a user?
      # - If they have can_view_referrals at the target project, OR
      # - If they have can_view_own_referrals, AND are assigned a step in the referral.

      base_scope = joins(:target_project)

      # Referrals that the user can view because they have can_view_referrals in the target project
      access_through_project = base_scope.
        merge(Hmis::Hud::Project.viewable_by(user).with_access(user, :can_view_referrals))

      # Referrals that have a step assigned to this user, in projects in which the user can_view_own_referrals.
      # Referral only becomes viewable once the assigned step becomes available.
      # Note that the user does *not* need can_view_project in this case
      own_referral_ids = base_scope.with_available_step_assigned_to(user).
        merge(Hmis::Hud::Project.with_access(user, :can_view_own_referrals)).
        pluck(:id) # pluck to avoid duplicates in resulting scope (from the step join)

      access_through_project.or(base_scope.where(id: own_referral_ids))
    end

    # Referrals that have a step assigned to the specified user. Excludes referrals if the assigned step(s) are unavailable.
    scope :with_available_step_assigned_to, ->(user) do
      assigned_step_ids = user.workflow_step_assignments.pluck(:step_id)
      joins(:steps).merge(Hmis::WorkflowExecution::Step.where(id: assigned_step_ids).excluding_unavailable)
    end

    scope :active, -> { where.not(status: ['accepted', 'rejected']) }
    scope :active_or_accepted, -> { where.not(status: 'rejected') }

    # Default sort for displaying referrals. Floats 'in_progress' and 'initialized' to the top,
    # then sorts by updated_at descending.
    # This is used in the frontend to display referrals in a consistent order.
    scope :order_by_status, -> do
      conditions = [
        [arel_table[:status].eq('initialized'), 1],
        [arel_table[:status].eq('in_progress'), 1],
        [arel_table[:status].eq('accepted'), 2],
        [arel_table[:status].eq('rejected'), 2],
      ]
      order(acase(conditions, elsewise: 3), updated_at: :desc, id: :asc)
    end

    validates :workflow_instance, uniqueness: true
    validate :unique_referral_per_opportunity
    validate :ce_template
    validate :consistent_data_source

    state_machine_config column: 'status' do
      state :initialized, initial: true
      state :in_progress
      state :accepted
      state :rejected

      event :start do
        transitions from: :initialized, to: :in_progress
      end
      event :accept do
        transitions from: :in_progress, to: :accepted
      end
      event :reject do
        transitions from: :in_progress, to: :rejected
      end
      # event :stall do
      #   transitions from: :active, to: :stalled
      # end
    end

    def workflow_engine
      @workflow_engine ||= Hmis::WorkflowExecution::Engine.new(
        workflow_instance,
        message_handler: Hmis::Ce::ReferralMessageHandler.new(self),
        assignment_handler: Hmis::Ce::ReferralTaskAssignmentHandler.new(self),
      )
    end

    def active?
      !accepted? && !rejected?
    end

    def self.apply_filters(input)
      Hmis::Filter::CeReferralFilter.new(input).filter_scope(self)
    end

    # Returns an array of fields referenced by Match Rules for this referral's opportunity,
    # with their current values for the referred Client's _Destination_ Client record.
    #
    # NOTE: This field intentionally does not check viewable_by scopes on the associated data;
    # it is resolved in the GraphQL API to expose pertinent data that the current user may not otherwise have permission to view.
    def resolve_match_rule_fields
      destination_client = client.destination_client&.as_warehouse
      return [] unless destination_client # if for whatever reason the client doesn't have a destination client, we cannot resolve the fields

      field_map = Hmis::Ce::Match::FieldMap.new
      calculator = Hmis::Ce::Match::CalculatorFactory.build
      seen_field_names = Set.new

      # Fetch all match rules applicable to the opportunity
      # TODO: this should really be the rules _as they were_ when the referral was created, not the current rules
      match_rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity)
      match_rules.sort_by(&:id).map do |rule|
        calculator.dependencies(rule.expression).map do |field|
          # Skip if Field has already been processed, for example expression "household_size = 1 OR household_size = 2"
          next if seen_field_names.include?(field)

          seen_field_names.add(field)
          label, value = field_map.resolve_field_for_display(destination_client, field)

          # OpenStruct resolves as HmisSchema::CeMatchValue
          OpenStruct.new(
            rule_id: rule.id,     # ID of rule that references this field
            rule_name: rule.name, # Name of rule that references this field
            field_name: label,
            field_values: Array.wrap(value),
          )
        end
      end.flatten.compact
    end

    private

    def unique_referral_per_opportunity
      # Opportunities are single-use, so there should only be one in-progress or accepted referral,
      # but there could be many rejected referrals.
      return if status.to_sym == :rejected

      conflicting_referral_exists = Hmis::Ce::Referral.where.not(status: 'rejected').
        where(opportunity_id: opportunity_id).
        where.not(id: id).
        exists?
      return unless conflicting_referral_exists

      errors.add(:opportunity, 'can only have one active or accepted referral')
    end

    def ce_template
      return if workflow_instance.template.template_type == 'ce_referral'

      errors.add(:workflow_instance, 'must be a CE template')
    end

    def consistent_data_source
      msg = 'must be in same data source as opportunity'

      # Opportunity takes the workflow template data source as the "source of truth", so do the same here
      data_source = opportunity.workflow_template.data_source

      errors.add(:client, msg) unless data_source == client.data_source
      errors.add(:target_enrollment, msg) if target_enrollment && data_source != target_enrollment.data_source
      # Source enrollment doesn't necessarily need to be in the same data source as the opportunity

      errors.add(:custom_status, msg) if custom_status && data_source != custom_status.data_source
    end
  end
end
