###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::AssessmentFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_assessment_name)).
      yield_self(&method(:with_project_type)).
      yield_self(&method(:with_project)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_assessment_name(scope)
    # "assessment_name" is either a HUD Role ('INTAKE') or a custom assessment form identifier ('my_assessment_form')
    hud_data_collection_stages = []
    custom_identifiers = []

    input.assessment_name.each do |t|
      hud_role_to_dcs = Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES.excluding(:CUSTOM_ASSESSMENT)
      if hud_role_to_dcs.include?(t.to_sym)
        hud_data_collection_stages << hud_role_to_dcs[t.to_sym]
      else
        custom_identifiers << t
      end
    end

    with_filter(scope, :assessment_name) do
      # we check data collection stage because migrated-in HUD Assessments may not be linked to a definition
      matches_hud_assessment = cas_t[:data_collection_stage].in(hud_data_collection_stages)
      matches_custom_assessment = fd_t[:identifier].in(custom_identifiers)

      scope.left_outer_joins(:definition).where(matches_hud_assessment.or(matches_custom_assessment))
    end
  end

  def with_project_type(scope)
    with_filter(scope, :project_type) { scope.with_project_type(input.project_type) }
  end

  def with_project(scope)
    with_filter(scope, :project) { scope.with_project(input.project) }
  end
end
