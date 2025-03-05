# frozen_string_literal: true

class Filters::Criteria::FilterForProjectsHud < Filters::Criteria::Base
  def applies? = input.project_ids.present?

  def apply(scope)
    scope = super(scope)
    scope.merge(viewable_project_scope).in_project(input.project_ids)
  end
end
