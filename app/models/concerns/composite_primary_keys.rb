module CompositePrimaryKeys
  extend ActiveSupport::Concern

  class_methods do
    def has_many_with_composite_keys(association_name, class_name:, keys:, **kwargs)
      composite_keys = [*keys, :data_source_id]
      has_many association_name,
        class_name: class_name,
        primary_key: composite_keys,
        query_constraints: composite_keys,
        **kwargs
    end

    def has_one_with_composite_keys(association_name, class_name:, keys:, **kwargs)
      composite_keys = [*keys, :data_source_id]
      has_one association_name,
        class_name: class_name,
        primary_key: composite_keys,
        query_constraints: composite_keys,
        **kwargs
    end

    def belongs_to_with_composite_keys(association_name, class_name:, keys:, **kwargs)
      composite_keys = [*keys, :data_source_id]
      belongs_to association_name,
        class_name: class_name,
        primary_key: composite_keys,
        query_constraints: composite_keys,
        **kwargs
    end
  end
end
