###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Enrollment for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    default_scope { unscope where: paranoia_column }

    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', foreign_key: [:EnrollmentID, :data_source_id], primary_key: [:EnrollmentID, :data_source_id], optional: true
    alias_attribute :enrollment, :enrollment_with_deleted
  end
end
