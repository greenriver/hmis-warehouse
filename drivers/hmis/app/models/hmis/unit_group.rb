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
    has_paper_trail(meta: { project_id: :project_id })

    belongs_to :project, class_name: 'Hmis::Hud::Project'
    has_many :units, class_name: 'Hmis::Unit', dependent: :destroy, foreign_key: :hmis_unit_group_id

    # The workflow template to use to fill CE Opportunities for Units belonging to this Unit Group
    belongs_to :workflow_template,
               -> { latest_versions }, # choose the most recent version of the template
               foreign_key: :workflow_template_identifier,
               primary_key: :identifier,
               class_name: 'Hmis::WorkflowDefinition::Template',
               optional: true

    validates :name, presence: true, uniqueness: { scope: :project_id, case_sensitive: false }
    validate :workflow_template_is_valid

    scope :viewable_by, ->(user) do
      joins(:project).merge(Hmis::Hud::Project.viewable_by(user).with_access(user, :can_view_units))
    end

    def eligibility_requirements
      Hmis::Ce::Match::Rule.eligibility_requirement.for_entity(self)
    end

    def priority_scheme
      Hmis::Ce::Match::Rule.priority_scheme.for_entity(self).first # TODO enforce 1 priority scheme?
    end

    def accepts_direct_ce_referrals?
      return false unless workflow_template.present?

      initiation_node = workflow_template.graph.nodes.find(&:delegated_handoff)
      return false unless initiation_node.present?
      return false unless initiation_node.user_task?
      return false unless initiation_node.form_definition.present?

      true
    end

    def available_unit_count
      units.accepting_ce_referrals.count
    end

    private

    def workflow_template_is_valid
      return unless workflow_template

      errors.add(:workflow_template_identifier, 'must be published') unless workflow_template.published?
      errors.add(:workflow_template_identifier, 'must belong to the same data source') if workflow_template.data_source_id != project.data_source_id
      errors.add(:workflow_template_identifier, 'must have a template type of ce_referral') unless workflow_template.template_type&.to_s == 'ce_referral'
    end
  end
end
