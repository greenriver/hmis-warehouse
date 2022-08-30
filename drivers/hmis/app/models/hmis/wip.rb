class Hmis::Wip < GrdaWarehouseBase
  belongs_to :source, polymorphic: true
  belongs_to :client, class_name: 'Hmis::"Hud::Client'
  belongs_to :enrollment, class_name: 'Hmis::Hus:Enrollment', optional: true
  belongs_to :project, class_name: 'Hmis::Hus:Project', optional: true
end
