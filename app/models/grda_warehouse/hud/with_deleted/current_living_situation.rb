# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of CurrentLivingSituation for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class CurrentLivingSituation < GrdaWarehouse::Hud::CurrentLivingSituation
    default_scope { unscope where: paranoia_column }

    alias_method :enrollment, :enrollment_with_deleted
  end
end
