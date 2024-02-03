###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::ApplicationUserFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope = with_search_term(scope)
    scope
  end

  protected

  def with_search_term(scope)
    search_term = input.search_term.strip
    return scope unless search_term.present?

    u_t = Hmis::User.arel_table

    field = Arel::Nodes::NamedFunction.new('CONCAT_WS', [u_t[:first_name], u_t[:last_name], u_t[:email]])
    query = "%#{search_term.split(/\W+/).join('%')}%"
    scope.where(field.matches(query))
  end
end
