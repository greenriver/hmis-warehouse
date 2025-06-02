###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

    def eligibility_requirements
      Hmis::Ce::Match::Rule.eligibility_requirement.for_entity(self)
    end

    def priority_scheme
      Hmis::Ce::Match::Rule.priority_scheme.for_entity(self).first # TODO enforce 1 priority scheme?
    end

    private

    def workflow_template_is_valid
      return unless workflow_template

      errors.add(:workflow_template_identifier, 'must be published') unless workflow_template.published?
      errors.add(:workflow_template_identifier, 'must belong to the same data source') if workflow_template.data_source_id != project.data_source_id
      errors.add(:workflow_template_identifier, 'must have a template type of ce_referral') if workflow_template.template_type == :ce_referral
    end
  end
end
