###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::FormDefinitionFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope = with_search_term(scope)
    scope
  end

  protected

  def with_search_term(scope)
    search_term = input.search_term&.strip
    return scope unless search_term.present?

    field = Arel::Nodes::NamedFunction.new('CONCAT_WS', [fd_t[:title], fd_t[:identifier], fd_t[:role]])
    query = "%#{search_term.split(/\W+/).join('%')}%"
    scope.where(field.matches(query))
  end
end
