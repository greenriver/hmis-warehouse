# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of AssessmentQuestion for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class AssessmentQuestion < GrdaWarehouse::Hud::AssessmentQuestion
    default_scope { unscope where: paranoia_column }

    alias_method :assessment, :assessment_with_deleted
    alias_method :enrollment, :enrollment_with_deleted
  end
end
