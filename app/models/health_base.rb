###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HealthBase < ActiveRecord::Base
  establish_connection DB_HEALTH
  self.abstract_class = true
  has_paper_trail versions: {class_name: Health::HealthVersion.name}

  include ArelHelper
  class << self
    cattr_accessor :phi_dictionary

    def phi_dictionary_entry
      self.phi_dictionary ||= {}
      self.phi_dictionary[self.name] ||= {
        patient_id: nil,
        attrbutes: Set.new
      }
    end

    def phi_attr(attribute, category)
      raise ArgumentError, "category (#{category}) must be a ::Phi::Category" unless category < ::Phi::Category
      raise ArgumentError, "attr (#{attr})  must method name as a symbol" unless attribute.is_a?(::Symbol)
      self.phi_dictionary_entry[:attrbutes] << ::Phi::Attribute.new(
        self.name,
        attribute,
        category
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
end
