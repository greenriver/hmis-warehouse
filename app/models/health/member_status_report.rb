module Health
  class MemberStatusReport < HealthBase

    scope :visible_by?, -> (user) do
      if user.can_view_member_health_reports? || user.can_view_aggregate_health? || user.can_administer_health?
        all
      else
        none
      end
    end
  end
end