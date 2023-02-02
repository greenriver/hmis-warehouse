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

    def recent_items
      sorted_recent_item_links.preload(:item).map(&:item)
    end

    def add_recent_item(item)
      association_name, = recent_item_types.find { |_name, item_class| item.is_a?(item_class) }
      raise "Cannot resolve recent item type for '#{item&.class&.name}' with id '#{item&.id}'" unless association_name.present?

      recent_item_links.find_or_create_by(item: item)&.touch
    end

    def clear_recent_items
      recent_item_links.destroy_all
    end

    def sorted_recent_item_links
      recent_item_links.order(updated_at: :desc)
    end
  end

  class_methods do
    @recent_item_types = {}

    def recent_item_types
      @recent_item_types
    end

    # This method should not be converted to 'recent?'
    # It does not query whether this item is recent, it declares a recent item type on the inheriting class
    # rubocop:disable Naming/PredicateName
    def has_recent(item_type, item_class, name: nil)
      association_name = name || "recent_#{item_type}".to_sym
      has_many association_name, through: :recent_item_links, source: :item, source_type: item_class.name
      @recent_item_types = {} if @recent_item_types.nil?
      @recent_item_types[association_name] = item_class
    end
    # rubocop:enable Naming/PredicateName
  end
end
