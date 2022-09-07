class Hmis::Wip < GrdaWarehouseBase
  belongs_to :source, polymorphic: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :project, class_name: '::Hmis::Hud::Project', optional: true
end
