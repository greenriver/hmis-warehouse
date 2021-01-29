###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse

  # NOTE, this is a join table where the users are in one database and the entities are in another.  You will usually have to pluck ids to be successful.

  class UserViewableEntity < GrdaWarehouseBase
    has_paper_trail(
      meta: { referenced_user_id: :user_id, referenced_entity_name: :entity_name }
    )
    acts_as_paranoid

    belongs_to :entity, polymorphic: true
    belongs_to :user

    scope :data_source, -> do
      where(entity_type: 'GrdaWarehouse::DataSource' )
    end

    def entity_name
      entity.name
    end

    def self.describe_changes(version, changes)
      if version.event == 'create'
        [ "Added #{version.referenced_entity_name} to #{humanize_entity_type_name(changes[:entity_type].last)}." ]
      else
        current = version.reify
        [ "Removed #{version.referenced_entity_name} from #{humanize_entity_type_name(current.entity_type)}." ]
      end
    end

    def self.humanize_entity_type_name(name)
      name.split('::').last.underscore.pluralize.humanize.titleize
    end
  end
end
