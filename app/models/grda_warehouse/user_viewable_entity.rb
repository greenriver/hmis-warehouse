module GrdaWarehouse

  # NOTE, this is a join table where the users are in one database and the entities are in another.  You will usually have to pluck ids to be successful.

  class UserViewableEntity < GrdaWarehouseBase
    has_paper_trail(
      meta: { referenced_user_id: :user_id, referenced_entity_name: :entity_name }
    )
    acts_as_paranoid

    belongs_to :entity, polymorphic: true
    belongs_to :user

    def entity_name
      entity.name
    end
  end
end