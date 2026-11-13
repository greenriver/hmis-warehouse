###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Filters for the Forms admin table, which lists one row per form identifier (the latest version of
# each form). Note that "Form Type" is the user-facing name for a form's role.
class Hmis::Filter::FormDefinitionFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope = with_search_term(scope)
    scope = with_form_types(scope)
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

  def with_form_types(scope)
    with_filter(scope, :form_type) { scope.where(role: input.form_type) }
  end
end
