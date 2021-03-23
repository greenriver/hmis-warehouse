###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Base
  extend ActiveSupport::Concern

  included do
    scope :delete_pending, -> do
      where.not(pending_date_deleted: nil)
    end
  end

  module ClassMethods
    def hud_paranoid_column
      :DateDeleted
    end

    # an array (in order) of the expected columns for hud CSV data
    def hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    # Override in sub-classes as necessary
    def hud_primary_key
      hud_csv_headers.first
    end

    ## convenience methods to DRY up some association definitions

    def bipartite_keys(col, model_name = nil)
      h = {
        primary_key: [
          :data_source_id,
          col,
        ],
        foreign_key: [
          :data_source_id,
          col,
        ],
        autosave: false,
      }
      h.merge! class_name: "GrdaWarehouse::Hud::#{model_name}" if model_name
      h
    end

    def hud_enrollment_belongs(model_name = nil)
      model_name = if model_name.present?
        "GrdaWarehouse::Hud::#{model_name}"
      else
        'GrdaWarehouse::Hud::Enrollment'
      end
      h = {
        primary_key: [
          :EnrollmentID,
          :PersonalID,
          :data_source_id,
        ],
        foreign_key: [
          :EnrollmentID,
          :PersonalID,
          :data_source_id,
        ],
        class_name: model_name,
        autosave: false,
      }
      h
    end

    def hud_assoc(col, model_name)
      bipartite_keys col, model_name
    end

    def hud_key=(key)
      @hud_key = key
    end

    def hud_key
      @hud_key
    end

    def conflict_target=(value)
      @conflict_target = value
    end

    def conflict_target
      @conflict_target || [:data_source_id, "\"#{hud_key}\""]
    end

    def additional_upsert_columns=(names)
      @additional_upsert_columns = names
    end

    def additional_upsert_columns
      @additional_upsert_columns || []
    end

    def upsert_column_names(version: nil)
      @upsert_column_names ||= (hud_csv_headers(version: version) +
        [:source_hash, :pending_date_deleted] +
        additional_upsert_columns -
        conflict_target).uniq
    end

    def related_item_keys
      []
    end

    def hmis_table_create!(version: nil, constraints: true, types: true)
      return if connection.table_exists?(table_name)

      connection.create_table table_name do |t|
        hmis_structure(version: version).each do |column, options|
          type = if types
            options[:type]
          else
            :string
          end
          if constraints
            t.send(type, column, options.except(:type))
          else
            t.send(type, column)
          end
        end
      end
    end

    def hmis_table_create_indices!(version: nil)
      hmis_indices(version: version).each do |columns, _|
        # enforce a short index name
        # cols = columns.map { |c| "#{c[0..5]&.downcase}#{c[-4..]&.downcase}" }
        # name = ([table_name[0..4]+table_name[-4..]] + cols).join('_')
        name = table_name.gsub(/[^0-9a-z ]/i, '') + '_' + SecureRandom.alphanumeric(4)
        next if connection.index_exists?(table_name, columns, name: name)

        connection.add_index table_name, columns, name: name
      end
    end

    def hmis_structure(version: nil)
      hmis_configuration(version: version).transform_values { |v| v.select { |k| k.in?(HMIS_STRUCTURE_KEYS) } }
    end

    HMIS_STRUCTURE_KEYS = [:type, :limit, :null].freeze
  end
end
