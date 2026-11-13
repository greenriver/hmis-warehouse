###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForDestination < Filters::Criteria::Base
  def applies? = input.destination_ids.present?

  def apply(scope)
    scope = super(scope)
    scope.where(destination: input.destination_ids)
  end
end
