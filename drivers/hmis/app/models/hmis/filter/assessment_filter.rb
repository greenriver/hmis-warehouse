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
    hud_types = []
    custom_types = []

    input.assessment_name.each do |t|
      if Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES.excluding(:CUSTOM_ASSESSMENT).keys.include?(t.to_sym)
        hud_types << t
      else
        custom_types << t
      end
    end

    with_filter(scope, :assessment_name) do
      scope.joins(:definition).with_role(hud_types).or(scope.with_form_definition_identifier(custom_types))
    end
  end

  def with_project_type(scope)
    with_filter(scope, :project_type) { scope.with_project_type(input.project_type) }
  end

  def with_project(scope)
    with_filter(scope, :project) { scope.with_project(input.project) }
  end
end
