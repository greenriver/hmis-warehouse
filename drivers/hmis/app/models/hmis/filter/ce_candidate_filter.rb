###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeCandidateFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:exclude_recently_declined_from_unit_group)).
      yield_self(&method(:clean_scope))
  end

  protected

  def exclude_recently_declined_from_unit_group(scope)
    with_filter(scope, :exclude_recently_declined_from_unit_group) do
      Hmis::Ce::FilteredCandidatesQuery.new(
        candidate_scope: scope,
        exclude_recently_declined_from_unit_group_ids: input.exclude_recently_declined_from_unit_group,
      ).resolve
    end
  end
end
