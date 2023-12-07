###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::FormInstanceFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_form_type)).
      yield_self(&method(:with_service_category)).
      yield_self(&method(:with_project_type)).
      yield_self(&method(:for_project)).
      yield_self(&method(:for_services)).
      yield_self(&method(:with_active_status)).
      yield_self(&method(:with_system_status)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_form_type(scope)
    with_filter(scope, :form_type) do
      # TODO: filter active status / max version
      identifiers = Hmis::Form::Definition.where(role: input.form_type).pluck(:identifier)

      scope.where(definition_identifier: identifiers)
    end
  end

  def with_service_category(scope)
    with_filter(scope, :service_category) do
      category_ids = input.service_category
      type_ids = Hmis::Hud::CustomServiceType.where(custom_service_cateogry_id: category_ids).pluck(:id)

      scope.where(custom_service_category_id: category_ids).or(custom_service_type_id: type_ids)
    end
  end

  def with_project_type(scope)
    with_filter(scope, :project_type) { scope.where(project_type: input.project_type) }
  end

  def for_project(scope)
    with_filter(scope, :applied_to_project) do
      project = Hmis::Hud::Project.find_by(id: input.applied_to_project)
      return scope.none unless project

      scope.for_project_through_entities(project)
    end
  end

  def for_services(scope)
    with_filter(scope, :for_services) do
      if input.for_services
        scope.for_services
      else
        scope.not_for_services
      end
    end
  end

  def with_active_status(scope)
    with_filter(scope, :active_status) do
      return scope.active if input.active_status == true
      return scope.inactive if input.active_status == false

      scope
    end
  end

  def with_system_status(scope)
    with_filter(scope, :system_form) do
      return scope.system if input.system_form == true
      return scope.not_system if input.system_form == false

      scope
    end
  end
end
