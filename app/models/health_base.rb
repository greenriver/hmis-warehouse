###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HealthBase < HealthDbBase
  include CustomApplicationRecord

  self.abstract_class = true
  connects_to database: { writing: :health, reading: :health }

  # Version records for every Health model live in the health database via
  # Health::HealthVersion. HealthBase enables paper_trail for the whole
  # hierarchy here, so subclasses inherit versioning automatically.
  #
  # paper_trail 16+ forbids calling has_paper_trail more than once, and the
  # inclusion it checks is inherited -- so any subclass that calls
  # has_paper_trail again (e.g. to add an `ignore:`) would raise. We override
  # the class method to force the correct version
  # class and, on a second (subclass) call, merge the new options into the
  # already-configured options instead of re-running setup (which would stack
  # callbacks and write duplicate version records).
  FORCED_VERSIONS = { class_name: 'Health::HealthVersion' }.freeze

  def self.has_paper_trail(options = {}) # rubocop:disable Naming/PredicatePrefix
    if respond_to?(:paper_trail_options) && paper_trail_options.present?
      self.paper_trail_options = merge_paper_trail_options(options)
      return
    end

    versions = options.fetch(:versions, {}).merge(FORCED_VERSIONS)
    super(options.merge(versions: versions))
  end

  # Merge a subclass's paper_trail options into the already-configured options,
  # normalizing ignore/skip/only to the stringified form paper_trail expects at
  # event time (see PaperTrail::ModelConfig#event_attribute_option). Does not
  # re-run setup, so no duplicate callbacks/versions, and leaves version_class_name
  # untouched so every Health model keeps versioning into Health::HealthVersion.
  def self.merge_paper_trail_options(options)
    merged = paper_trail_options.dup
    [:ignore, :skip, :only].each do |key|
      next unless options.key?(key)

      merged[key] = Array(options[key]).flatten.compact.map do |attr|
        attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s
      end
    end
    merged[:meta] = merged[:meta].to_h.merge(options[:meta]) if options[:meta]
    merged
  end

  has_paper_trail

  class << self
    attr_accessor :phi_dictionary

    def phi_dictionary_entry
      self.phi_dictionary ||= {}
      self.phi_dictionary[name] ||= {
        patient_id: nil,
        attrbutes: Set.new,
      }
    end

    def phi_attr(attribute, category = nil, description = nil)
      raise ArgumentError, "category (#{category}) must be a ::Phi::Category" unless category < ::Phi::Category
      raise ArgumentError, "attr (#{attr})  must method name as a symbol" unless attribute.is_a?(::Symbol)

      phi_dictionary_entry[:attrbutes] << ::Phi::Attribute.new(
        name,
        attribute,
        category,
        description,
      )
    end

    def phi_patient(attribute)
      raise ArgumentError, "attr (#{attr})  must method name as a symbol" unless attribute.is_a?(::Symbol)
      if (existing = phi_dictionary_entry[:patient_id]) && existing != attribute
        raise ArgumentError, "Cannot set more then one phi_patient per class: class:#{self} existing: #{existing}, new: #{attribute}"
      end

      phi_dictionary_entry[:table_name] = table_name
      phi_dictionary_entry[:patient_id] = attribute
    end
  end
end
