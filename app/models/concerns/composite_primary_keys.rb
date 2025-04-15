module CompositePrimaryKeys
  extend ActiveSupport::Concern

  class_methods do
    def has_many_with_composite_keys(association_name, *args, keys:, **kwargs)
      composite_keys_association(:has_many, association_name, *args, keys: keys, **kwargs)
    end

    def has_one_with_composite_keys(association_name, *args, keys:, **kwargs)
      composite_keys_association(:has_one, association_name, *args, keys: keys, **kwargs)
    end

    def belongs_to_with_composite_keys(association_name, *args, keys:, **kwargs)
      composite_keys_association(:belongs_to, association_name, *args, keys: keys, **kwargs)
    end

    private

    def composite_keys_association(type, association_name, *args, keys:, **kwargs)
      composite_keys = [*keys, :data_source_id]
      opts = { primary_key: composite_keys, query_constraints: composite_keys }.merge(kwargs)
      if args.first.is_a?(Proc)
        send(type, association_name, args.first, **opts)
      else
        send(type, association_name, **opts)
      end
    end
  end
end
