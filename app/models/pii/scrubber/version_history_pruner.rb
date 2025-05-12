###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Delete paper trail versions for a model
# * handle versions for aliases (GrdaWarehouse::Hud::Client and Hmis::Hud::Client)
# * accounts for different version backing tables
module Pii::Scrubber
  class VersionHistoryPruner
    def perform(owner:, ids: nil)
      # the model does not use paper trail
      return unless owner.include?(::PaperTrail::Model::InstanceMethods)

      item_classes = ([owner] + model_aliases(owner)).uniq
      item_types = item_classes.map(&:sti_name)

      version_class = owner.version_class_name.constantize
      to_delete = version_class.where(item_type: item_types)
      to_delete = to_delete.where(item_id: ids) if ids

      to_delete.delete_all
    end

    protected

    # Finds model aliases across GrdaWarehouse/Hmis namespaces that share the same backing table
    def model_aliases(model)
      results = [
        model.sti_name.sub(/\AGrdaWarehouse/, 'Hmis'),
        model.sti_name.sub(/\AHmis/, 'GrdaWarehouse'),
      ].map do |name|
        model_alias = try_constantize(name)
        next unless model_alias
        next unless same_backing_table?(model, model_alias)

        model_alias
      end
      results.compact_blank
    end

    def try_constantize(name)
      name.constantize
    rescue NameError
      nil
    end

    def same_backing_table?(model1, model2)
      model1.connection.current_database == model2.connection.current_database && model1.table_name == model2.table_name
    end
  end
end
