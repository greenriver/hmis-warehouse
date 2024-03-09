###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::ServiceTypeFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope = with_search_term(scope)
    scope = with_include_hud_services(scope)
    scope
  end

  protected

  def with_search_term(scope)
    search_term = input.search_term.strip
    return scope unless search_term.present?

    field = Arel::Nodes::NamedFunction.new('CONCAT_WS', [cst_t[:name], csc_t[:name]])
    query = "%#{search_term.split(/\W+/).join('%')}%"
    scope.joins(:custom_service_category).where(field.matches(query))
  end

  def with_include_hud_services(scope)
    if input.include_hud_services
      scope.hud_service_types
    else
      scope
    end
  end
end
