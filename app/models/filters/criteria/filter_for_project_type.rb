###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForProjectType < Filters::Criteria::Base
  def applies?
    config.all_project_types ? false : project_types.present?
  end

  def apply(scope)
    scope = super(scope)
    scope.in_project_type(project_types)
  end

  protected

  def project_types
    result = config.project_types || input.project_type_ids
    result += HudUtilityCurrent.performance_reporting[:ce] if input.coordinated_assessment_living_situation_homeless || input.ce_cls_as_homeless
    result
  end
end
