#
# DB VIEW: includes both enrollments and WIP
class Hmis::Hud::ClientProject < GrdaWarehouseBase
  belongs_to :client, class_name: 'Hmis::Hud::Client'
  belongs_to :project, class_name: 'Hmis::Hud::Project'
  belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment'
  has_one :household, through: :enrollment

  def readonly?
    true
  end

end
