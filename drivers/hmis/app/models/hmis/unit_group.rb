###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Represents a logical grouping of Hmis::Units within a specific Hmis::Hud::Project.
#
# - Supports Coordinated Entry (CE) Configuration:
#   - Associates a specific `workflow_template` (Hmis::WorkflowDefinition::Template)
#     to be used for CE Opportunities created for units within this group.
#   - Enables the definition of CE `eligibility_requirements` and `priority_scheme`
#     rules (Hmis::Ce::Match::Rule) that apply to all units in the group
module Hmis
  class UnitGroup < HmisBase
    acts_as_paranoid
    has_paper_trail(meta: { project_id: :project_id })

    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool', optional: true
    belongs_to :unit_type, class_name: 'Hmis::UnitType', optional: true
    has_many :units, class_name: 'Hmis::Unit', dependent: :destroy, foreign_key: :hmis_unit_group_id
    has_many :unit_types, through: :units # TODO(#8157) - Unit should have at most 1 unit type. Remove when no longer used
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', through: :units

    # The workflow template to use to fill CE Opportunities for Units belonging to this Unit Group
    belongs_to :workflow_template,
               -> { latest_versions }, # choose the most recent version of the template
               foreign_key: :workflow_template_identifier,
               primary_key: :identifier,
               class_name: 'Hmis::WorkflowDefinition::Template',
               optional: true

    # The workflow template to use for direct referrals to Units belonging to this Unit Group
    belongs_to :direct_referral_workflow_template,
               -> { latest_versions }, # choose the most recent version of the template
               foreign_key: :direct_referral_workflow_template_identifier,
               primary_key: :identifier,
               class_name: 'Hmis::WorkflowDefinition::Template',
               optional: true

    validates :name, presence: true, uniqueness: { scope: :project_id, case_sensitive: false, message: 'must be unique in the project' }
    validate :workflow_template_is_valid
    validate :workflow_template_is_stable
    validate :direct_referral_workflow_template_is_valid
    validate :direct_referral_workflow_template_is_stable
    validate :project_is_not_changed, on: :update
    validate :unit_type_is_stable, on: :update

    after_create :rebuild_candidate_pool

    scope :viewable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.viewable_by(user).with_access(user, :can_view_units))
    end

    scope :with_ce_waitlists_enabled, -> do
      joins(:project).merge(Hmis::Hud::Project.with_ce_waitlists_enabled)
    end

    def eligibility_requirements
      Hmis::Ce::Match::Rule.eligibility_requirements_for_entity(self)
    end

    def priority_schemes
      Hmis::Ce::Match::Rule.priority_schemes_for_entity(self)
    end

    def available_unit_count
      units.receiving_referrals.count
    end

    private

    def project_is_not_changed
      errors.add(:project, 'cannot be changed') if will_save_change_to_project_id?
    end

    def rebuild_candidate_pool
      Hmis::Ce::Match::CandidatePool.lock_for_maintenance! do
        Hmis::Ce::Match::CandidatePoolBuilder.call(unit_group_ids: [id])
      end
    end

    def workflow_template_is_valid
      return unless workflow_template

      errors.add(:workflow_template_identifier, 'must be published') unless workflow_template.published?
      errors.add(:workflow_template_identifier, 'must belong to the same data source') if workflow_template.data_source_id != project.data_source_id
      errors.add(:workflow_template_identifier, 'must have a template type of ce_referral') unless workflow_template.template_type&.to_s == 'ce_referral'
    end

    def workflow_template_is_stable
      return unless workflow_template_identifier_changed?
      return if workflow_template_identifier_was.nil?

      errors.add(:workflow_template_identifier, 'cannot be changed once set')
    end

    def direct_referral_workflow_template_is_valid # todo @martha - can these be combined?
      return unless direct_referral_workflow_template

      errors.add(:direct_referral_workflow_template_identifier, 'must be published') unless direct_referral_workflow_template.published?
      errors.add(:direct_referral_workflow_template_identifier, 'must belong to the same data source') if direct_referral_workflow_template.data_source_id != project.data_source_id
      errors.add(:direct_referral_workflow_template_identifier, 'must have a template type of ce_referral') unless direct_referral_workflow_template.template_type&.to_s == 'ce_referral'

      # Validate that the workflow has the correct structure for direct referrals
      validate_direct_referral_workflow_structure
    end

    def direct_referral_workflow_template_is_stable
      return unless direct_referral_workflow_template_identifier_changed?
      return if direct_referral_workflow_template_identifier_was.nil?

      errors.add(:direct_referral_workflow_template_identifier, 'cannot be changed once set')
    end

    def unit_type_is_stable
      return unless unit_type_id_changed?
      return if unit_type_id_was.nil?

      errors.add(:unit_type_id, 'cannot be changed once set')
    end

    def validate_direct_referral_workflow_structure # todo @Martha - where was this generated from, who was validating it before?
      return unless direct_referral_workflow_template

      entrypoint_ids = direct_referral_workflow_template.nodes.entrypoints.pluck(:id)
      # Walk the graph, passing the entrypoints as starting points so they aren't included in the results
      walk = direct_referral_workflow_template.graph.walk(entrypoint_ids: entrypoint_ids, stop_when: lambda(&:user_task?))
      # Expect that exactly one user task is returned
      return if walk.count == 1

      errors.add(:direct_referral_workflow_template_identifier, 'workflow template structure is not valid for direct referrals')
    end
  end
end
