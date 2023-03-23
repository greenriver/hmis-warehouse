###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HasRecentItems
  extend ActiveSupport::Concern
  included do
    has_many :recent_item_links, as: :owner, class_name: 'GrdaWarehouse::RecentItem'

    def recent_item_types
      self.class.recent_item_types
    end

    def viewable_map
      self.class.viewable_map
    end

    def recent_items
      viewable_recent_item_links.order(updated_at: :desc).preload(:item).map(&:item).compact
    end

    def viewable_recent_item_links
      return recent_item_links if viewable_map.compact.empty?

      ids = []

      recent_item_types.values.map do |item_class|
        ri_scope = recent_item_links.where(item_type: item_class.name)
        ri_scope = ri_scope.where(item_id: viewable_map[item_class.name].call(self, ri_scope).pluck(:id)) if viewable_map[item_class.name].present?
        ids += ri_scope.pluck(:id)
      end

      recent_item_links.where(id: ids)
    end

    def add_recent_item(item)
      association_name, = recent_item_types.find { |_name, item_class| item.is_a?(item_class) }
      raise "Cannot resolve recent item type for '#{item&.class&.name}' with id '#{item&.id}'" unless association_name.present?

      recent_item_links.find_or_create_by(item: item)&.touch
    end

    def clear_recent_items
      recent_item_links.destroy_all
    end
  end

  class_methods do
    @recent_item_types = {}
    @viewable_map = {}

    def recent_item_types
      @recent_item_types
    end

    def viewable_map
      @viewable_map ||= {}
    end

    # This method should not be converted to 'recent?'
    # It does not query whether this item is recent, it declares a recent item type on the inheriting class
    # rubocop:disable Naming/PredicateName
    def has_recent(item_type, item_class, name: nil, viewable_proc: nil)
      association_name = name || "recent_#{item_type}".to_sym
      has_many association_name, through: :recent_item_links, source: :item, source_type: item_class.name
      @recent_item_types = {} if @recent_item_types.nil?
      @recent_item_types[association_name] = item_class
      viewable_map[item_class.name] = viewable_proc
    end
    # rubocop:enable Naming/PredicateName
  end
end
