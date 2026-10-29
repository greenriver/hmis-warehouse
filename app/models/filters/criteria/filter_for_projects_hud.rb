###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForProjectsHud < Filters::Criteria::Base
  def applies? = input.project_ids.present?

  def apply(scope)
    scope = super(scope)
    # Viewable and selected projects in one merge; merging them separately lets the
    # second `where` on the project id replace the first
    scope.joins(:project).merge(viewable_project_scope.where(id: input.project_ids))
  end
end
