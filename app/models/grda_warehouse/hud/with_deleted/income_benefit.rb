###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTE: This provides an unscoped duplicate of IncomeBenefit for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class IncomeBenefit < GrdaWarehouse::Hud::IncomeBenefit
    default_scope { unscope where: paranoia_column }

    alias_method :enrollment, :enrollment_with_deleted
  end
end
