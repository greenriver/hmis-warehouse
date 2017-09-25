module GrdaWarehouse
  class UserClient < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid
    
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user

    def self.available_users
      User.all
    end

    def self.available_relationships
      [
        'Navigator',
        'Case Manager',
        'Nurse Care Manager',
      ].sort.freeze
    end
  end
end
