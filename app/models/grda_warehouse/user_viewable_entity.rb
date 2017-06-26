module GrdaWarehouse

  # NOTE, this is a join table where the users are in one database and the entities are in another
  # there is in fact a belongs_to relationship to the user table, therefore, but it isn't specified here
  class UserViewableEntity < GrdaWarehouseBase
    belongs_to :entity, polymorphic: true
  end
end