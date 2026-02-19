###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTE: This provides an unscoped duplicate of Exit for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Exit < GrdaWarehouse::Hud::Exit
    default_scope { unscope where: paranoia_column }

    alias_attribute :enrollment, :enrollment_with_deleted
  end
end
