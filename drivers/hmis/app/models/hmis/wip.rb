###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Wip < Hmis::HmisBase
  belongs_to :source, polymorphic: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :project, class_name: '::Hmis::Hud::Project', optional: true

  scope :assessments, -> { where(source_type: Hmis::Hud::Assessment.name) }
  scope :enrollments, -> { where(source_type: Hmis::Hud::Enrollment.name) }
end
