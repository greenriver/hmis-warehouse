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
    validate :validate_workflow_templates
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

    def template_for_direct_referrals
      # Default to workflow_template if direct_referral_workflow_template is not found.
      # This is for backwards compatibility while we switch over.
      direct_referral_workflow_template || workflow_template
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

    def validate_workflow_templates
      validate_template(workflow_template, :workflow_template_identifier)

      return unless direct_referral_workflow_template.present?

      validate_template(direct_referral_workflow_template, :direct_referral_workflow_template_identifier)

      # The template must have a direct_referral_form_definition for the direct referral initiator to fill out.
      # If this is nil, that indicates the structure is invalid.
      return unless direct_referral_workflow_template.direct_referral_form_definition.present?

      errors.add(:direct_referral_workflow_template_identifier, 'structure is not valid for direct referrals')
    end

    def validate_template(template, field_name)
      return unless template

      validate_field_stable_once_set(field_name)
      errors.add(field_name, 'must be published') unless template.published?
      errors.add(field_name, 'must belong to the same data source') if template.data_source_id != project.data_source_id
      errors.add(field_name, 'must have a template type of ce_referral') unless template.template_type&.to_s == 'ce_referral'
    end

    def validate_field_stable_once_set(field_name, error_field_name = field_name)
      changed_method = "#{field_name}_changed?"
      was_method = "#{field_name}_was"

      return unless send(changed_method)
      return if send(was_method).nil?

      errors.add(error_field_name, 'cannot be changed once set')
    end

    def unit_type_is_stable
      validate_field_stable_once_set(:unit_type_id, :unit_type)
    end
  end
end
