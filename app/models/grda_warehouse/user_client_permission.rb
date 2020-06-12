class GrdaWarehouse::UserClientPermission < GrdaWarehouseBase
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  validates :user_id, presence: true

  def self.query

    #super_user_ids = User.joins(:roles).merge(Role.where(name: 'can_edit_anything_super_user')).pluck(:id)
    super_user_ag_ids =
      AccessGroup.joins(:user).merge(User.has_permission(:can_edit_anything_super_user)).pluck(:id)

    # user.can_edit_anything_super_user?
    super_user_clients = <<~SQL
      --- user.can_edit_anything_super_user?
      select ag.id as ag_id, c.id as client_id from
        (select id from unnest(ARRAY[#{super_user_ag_ids.join(',')}]::int[]) as id) as ag,
        (#{GrdaWarehouse::Hud::Client.select(:id).to_sql}) as c
    SQL

    [
      super_user_clients,
    ].join (' UNION DISTINCT ')
  end

  def self.live!
    connection.select_rows query
  end
end
