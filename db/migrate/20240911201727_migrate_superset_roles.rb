class MigrateSupersetRoles < ActiveRecord::Migration[7.0]
  def up
    User.where.not(superset_roles: []).find_each do |u|
      roles = u.superset_roles
      roles.map! do |r|
        case r
        when 'Admin'
          'Warehouse Admin'
        when 'Reports Dashboard Read'
          'Report Runner'
        end
      end
      u.update(superset_roles: roles.compact)
    end
  end
end
