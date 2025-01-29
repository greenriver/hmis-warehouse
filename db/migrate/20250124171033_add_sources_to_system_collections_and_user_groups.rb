class AddSourcesToSystemCollectionsAndUserGroups < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::ProjectGroup.find_each do |pg|
      fix_entity_associations(pg)
    end
    GrdaWarehouse::Cohort.find_each do |c|
      fix_entity_associations(c)
    end
  end

  def fix_entity_associations(item)
    # If we already have a system collection in the new mechanism, do nothing
    existing_collection = Collection.system.where(source: item).exists?
    unless existing_collection
      # Find the last collection that would have been created under the old mechanism
      collection = Collection.system.where(name: item.name, collection_type: item.collection_type).
        order(id: :desc).
        first_or_create!
      collection.update(source: item)
    end

    # If we already have a viewable user group, do nothing
    existing_user_group = UserGroup.system.where(source: item, context: :viewable).exists?
    unless existing_user_group
      user_group = UserGroup.system.
        where(name: item.send(:viewable_user_group_name)). # Note: viewable_user_group_name is private, using it here as this will not be relevant after release-151
        order(id: :desc).
        first_or_create
      user_group.update(source: item, context: :viewable)
    end

    # If we already have a editable user group, do nothing
    existing_user_group = UserGroup.system.where(source: item, context: :editable).exists?
    unless existing_user_group
      user_group = UserGroup.system.
        where(name: item.send(:editable_user_group_name)). # Note: editable_user_group_name is private, using it here as this will not be relevant after release-151
        order(id: :desc).
        first_or_create!
      user_group.update(source: item, context: :editable)
    end

    self
  end
end
