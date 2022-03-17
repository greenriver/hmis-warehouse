class AddVprReferenceToFollowUps < ActiveRecord::Migration[6.1]
  def change
    add_reference :health_flexible_service_follow_ups, :vpr
  end
end
