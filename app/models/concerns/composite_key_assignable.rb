
module CompositeKeyAssignable
  extend ActiveSupport::Concern

  included do
    class_attribute :composite_sync_config, default: {}
    before_validation :sync_data_source_ids_from_composites # Register the single callback
  end

  module ClassMethods
    def composite_belongs_to(association_name, **options)
      # 1. Define the standard belongs_to association
      belongs_to association_name, **options

      # 2. Store configuration for the callback
      reflection = reflect_on_association(association_name)
      foreign_key_attr = reflection.foreign_key.to_sym
      # careful to re-assign so we don't leak config between classes
      self.composite_sync_config = self.composite_sync_config.merge(foreign_key_attr => association_name)

      # 3. Handle the direct assignment case (enrollment.project = some_project).
      # Provides immediate expected behavior for direct assignments in memory.
      define_method("#{association_name}=") do |new_obj|
        super(new_obj)
        self.data_source_id = new_obj&.data_source_id
        element_id = foreign_key_attr.to_s.gsub(/\Ads_/, '')
        self[element_id] = new_obj&.[](element_id)
      end
    end
  end

  # Update the target data source attribute on self.
  # This ensures correctness even if only the FK was set (e.g., via has_many <<)
  def sync_data_source_ids_from_composites
    self.class.composite_sync_config.each do |fk_attr, association_name|
      next unless send("#{association_name}_changed?")

      assoc_object = self.public_send(association_name)
      self.data_source_id = assoc_object&.data_source_id
      element_id = fk_attr.to_s.gsub(/\Ads_/, '')
      self[element_id] = assoc_object&.[](element_id)
    end
  end
end
