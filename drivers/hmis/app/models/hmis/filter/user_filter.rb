###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::UserFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope = with_search_term(scope)
    scope
  end

  protected

  def with_search_term(scope)
    search_term = input.search_term.strip
    return scope unless search_term.present?

    u_t = Hmis::Hud::User.arel_table

    field = Arel::Nodes::NamedFunction.new('CONCAT_WS', [u_t[:UserFirstName], u_t[:UserLastName], u_t[:UserEmail]])
    query = "%#{search_term.split(/\W+/).join('%')}%"
    scope.where(field.matches(query))
  end
end
