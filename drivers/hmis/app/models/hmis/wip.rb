class Hmis::Wip < GrdaWarehouseBase
  belongs_to :source, polymorphic: true
  belongs_to :client, class_name: '::Hmis::Hud::Client', primary_key: :PersonalID
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', primary_key: :EnrollmentID, optional: true
  belongs_to :project, class_name: '::Hmis::Hud::Project', primary_key: :ProjectID, optional: true
end
