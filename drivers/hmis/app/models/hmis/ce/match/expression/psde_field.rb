###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  PsdeField = Data.define(
    :key,
    :table,
    :column,
    :value_type,
    :label,
    :description,
  )
end
