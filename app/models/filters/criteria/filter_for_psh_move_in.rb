###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForPshMoveIn < Filters::Criteria::Base
  def applies? = input.psh_move_in

  def apply(scope)
    scope = super(scope)
    scope.in_project_type(3).where(move_in_date: input.range)
  end
end
