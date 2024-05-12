###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# for HUD entities that want to relate to a project through enrollments including WIP
module Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  extend ActiveSupport::Concern

  included do
    belongs_to :enrollment, **hmis_enrollment_relation, optional: true
    has_one :project, through: :enrollment
  end
end
