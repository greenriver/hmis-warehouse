###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer::CustomImportConcern
  extend ActiveSupport::Concern

  included do
    def as_destination_record
      config = self.class.custom_file_config

      if config['key_value_store']
        # Key-value stores are processed differently
        nil
      elsif config['augments_warehouse_table']
        as_augmentation_record
      elsif config['creates_warehouse_table']
        super
      end
    end

    private

    def as_augmentation_record
      config = self.class.custom_file_config
      warehouse_class = config['augments_warehouse_table'].constantize
      augment_key = config['augment_key']

      # Find the existing warehouse record
      existing_record = warehouse_class.find_by(
        data_source_id: data_source_id,
        augment_key => self[augment_key],
      )

      return nil unless existing_record

      # Apply all column mappings using the generic mapper
      mapped_attributes = {}
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(
        self,
        mapped_attributes,
        config['columns'],
      )

      # Apply mapped attributes to the existing record
      existing_record.assign_attributes(mapped_attributes)
      existing_record.source_hash = calculate_source_hash
      existing_record
    end
  end

  class_methods do
    def involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      config = custom_file_config

      if config['key_value_store']
        # Key-value stores don't follow normal scoping
        none
      elsif config['augments_warehouse_table']
        warehouse_class = config['augments_warehouse_table'].constantize
        if warehouse_class == GrdaWarehouse::Hud::Client
          # Special handling for Client augmentation
          warehouse_class.importable.joins(:source_enrollments).
            merge(GrdaWarehouse::Hud::Enrollment.joins(:project).
              merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
              open_during_range(date_range.range)).distinct
        else
          warehouse_class.where(data_source_id: data_source_id)
        end
      else
        super
      end
    end

    def warehouse_class
      config = custom_file_config
      if config['augments_warehouse_table']
        config['augments_warehouse_table'].constantize
      elsif config['creates_warehouse_table']
        config['warehouse_class_name'].constantize
      else
        super
      end
    end

    def hud_key
      custom_file_config['columns'].first['name'].to_sym
    end
  end
end
