###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Delete paper trail versions for a model
# * handle versions for aliases (GrdaWarehouse::Hud::Client and Hmis::Hud::Client)
# * accounts for different version backing tables
module Pii::Scrubber
  class VersionHistoryPruner
    def perform(owner:, ids: nil)
      # the model does not use paper trail
      return unless owner.include?(::PaperTrail::Model::InstanceMethods)

      version_class = owner.version_class_name.constantize
      to_delete = version_class.where(item_type: item_types(owner))
      if !sti_subclass?(owner)
        to_delete = to_delete.where(item_id: ids) if ids
      elsif ids
        to_delete = to_delete.where(item_id: owner.unscoped.where(id: ids).select(:id))
      else
        # The base class's table holds sibling STI types that share the version item_type.
        # Keep versions of live siblings; everything else is the owner's or an orphan
        # left by really_destroy!.
        live_siblings = owner.base_class.unscoped.where.not(owner.inheritance_column => owner.sti_name).select(:id)
        to_delete = to_delete.where.not(item_id: live_siblings)
      end

      to_delete.delete_all
    end

    protected

    # PaperTrail records STI models under the base class name
    def item_types(owner)
      return [owner.base_class.name] if sti_subclass?(owner)

      model = owner.base_class
      ([model] + model_aliases(model)).uniq.map(&:sti_name)
    end

    # Subclasses such as the WithDeleted variants share the base table without a type column
    def sti_subclass?(owner)
      owner.base_class != owner && owner.base_class.column_names.include?(owner.inheritance_column)
    end

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
