###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForVeteranStatus < Filters::Criteria::Base
  def applies? = input.veteran_statuses.present?

  def apply(scope)
    scope = super(scope)
    scope.joins(config.join_clients_method).
      where(arel.c_t[:VeteranStatus].in(input.veteran_statuses))
  end
end
