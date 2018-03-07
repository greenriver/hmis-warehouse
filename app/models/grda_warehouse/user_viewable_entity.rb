module GrdaWarehouse

  # NOTE, this is a join table where the users are in one database and the entities are in another.  You will usually have to pluck ids to be successful.

  class UserViewableEntity < GrdaWarehouseBase
    belongs_to :entity, polymorphic: true
    belongs_to :user
  end
end