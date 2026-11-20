###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Finds every concrete model that declares pii_attr, for the PII scrub task.
module Pii::Scrubber
  class ScrubbableModels
    # Staff login accounts; scrubbing their emails would lock people out of staging.
    EXCLUDED_MODEL_NAMES = ['User', 'Hmis::User'].freeze

    # Every concrete PII model with an existing table, including STI subclasses and
    # same-table aliases. Version history is pruned for all of these.
    def self.all
      Rails.application.eager_load! unless Rails.application.config.eager_load

      ActiveRecord::Base.descendants.
        select { |model| pii_model?(model) }.
        select(&:table_exists?).
        sort_by(&:name)
    end

    # The subset whose rows need scrubbing: drops STI subclasses covered by a
    # base class with the same config, and models duplicating another's table and config.
    def self.to_scrub
      all.
        reject { |model| covered_by_base_class?(model) }.
        uniq { |model| table_signature(model) }
    end

    def self.pii_model?(model)
      model.include?(HasPiiAttributes) &&
        model.stores_pii? &&
        model.name&.safe_constantize == model &&
        EXCLUDED_MODEL_NAMES.exclude?(model.name) &&
        !model.abstract_class?
    end
    private_class_method :pii_model?

    def self.covered_by_base_class?(model)
      base = model.base_class
      base != model && base.try(:stores_pii?) && base.pii_attributes_config == model.pii_attributes_config
    end
    private_class_method :covered_by_base_class?

    def self.table_signature(model)
      [
        model.connection_db_config.database,
        model.table_name,
        model.base_class == model ? nil : model.sti_name,
        model.pii_attributes_config,
      ]
    end
    private_class_method :table_signature
  end
end
