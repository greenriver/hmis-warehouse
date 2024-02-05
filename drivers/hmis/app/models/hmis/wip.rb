###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Wip < Hmis::HmisBase
  acts_as_paranoid
  has_paper_trail(
    meta: {
      project_id: ->(r) { r.project&.id },
      enrollment_id: ->(r) { r.enrollment&.id },
      client_id: ->(r) { r.client&.id },
    },
  )

  belongs_to :source, polymorphic: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :project, class_name: '::Hmis::Hud::Project', optional: true

  scope :assessments, -> { where(source_type: Hmis::Hud::CustomAssessment.sti_name) }
  scope :enrollments, -> { where(source_type: Hmis::Hud::Enrollment.sti_name) }
end
