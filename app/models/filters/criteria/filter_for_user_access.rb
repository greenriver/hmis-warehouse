###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForUserAccess < Filters::Criteria::Base
  def applies? = true

  def apply(scope)
    scope = super(scope)
    scope.joins(:project).merge(viewable_project_scope)
  end
end
