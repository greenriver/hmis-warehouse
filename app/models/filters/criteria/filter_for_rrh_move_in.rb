###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForRrhMoveIn < Filters::Criteria::Base
  def applies? = input.rrh_move_in

  def apply(scope)
    scope = super(scope)
    scope.in_project_type(13).where(move_in_date: input.range)
  end
end
