###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HealthBase < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :health, reading: :health }
  has_paper_trail versions: {class_name: 'Health::HealthVersion'}

  include ArelHelper
  class << self
    attr_accessor :phi_dictionary

    def phi_dictionary_entry
      self.phi_dictionary ||= {}
      self.phi_dictionary[self.name] ||= {
        patient_id: nil,
        attrbutes: Set.new
      }
    end

    def phi_attr(attribute, category= nil, description= nil)
      raise ArgumentError, "category (#{category}) must be a ::Phi::Category" unless category < ::Phi::Category
      raise ArgumentError, "attr (#{attr})  must method name as a symbol" unless attribute.is_a?(::Symbol)
      self.phi_dictionary_entry[:attrbutes] << ::Phi::Attribute.new(
        self.name,
        attribute,
        category,
        description
      )
    end

    def phi_patient(attribute)
      raise ArgumentError, "attr (#{attr})  must method name as a symbol" unless attribute.is_a?(::Symbol)
      if (existing = phi_dictionary_entry[:patient_id]) && existing != attribute
        raise ArgumentError, "Cannot set more then one phi_patient per class: class:#{self} existing: #{existing}, new: #{attribute}"
      end
      self.phi_dictionary_entry[:table_name] = table_name
      self.phi_dictionary_entry[:patient_id] = attribute
    end
  end

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/health/migrate', Health::SchemaMigration).needs_migration?
  end
end
