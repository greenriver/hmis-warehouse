###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#####
# DEPRECATED 🚨
# The EnrollmentCoC class has been deprecated as of 10/1/2024. The class is still needed by
# the importer to handle data from sources that ship in older formats.
#####

# NOTE: This provides an unscoped duplicate of Enrollment for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    default_scope { unscope where: paranoia_column }

    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', foreign_key: [:EnrollmentID, :data_source_id], primary_key: [:EnrollmentID, :data_source_id], optional: true
    alias_attribute :enrollment, :enrollment_with_deleted
  end
end
