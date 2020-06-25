###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Base < GrdaWarehouseBase
    self.abstract_class = true
    def self.hud_paranoid_column
      :DateDeleted
    end

    scope :delete_pending, -> do
      where.not(pending_date_deleted: nil)
    end

    # an array (in order) of the expected columns for hud CSV data
    def self.hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    # Override in sub-classes as necessary
    def self.hud_primary_key
      self.hud_csv_headers.first
    end

    ## convenience methods to DRY up some association definitions

    def self.bipartite_keys(col, model_name)
      h = {
        primary_key: [
          :data_source_id,
          col,
        ],
        foreign_key: [
          :data_source_id,
          col,
        ],
        autosave: false
      }
      h.merge! class_name: "GrdaWarehouse::Hud::#{model_name}" if model_name
      return h
    end

    def self.hud_enrollment_belongs model_name=nil
      model_name = if model_name.present?
        "GrdaWarehouse::Hud::#{model_name}"
      else
       'GrdaWarehouse::Hud::Enrollment'
      end
      h = {
        primary_key: [
          :EnrollmentID,
          :PersonalID,
          :data_source_id
        ],
        foreign_key: [
          :EnrollmentID,
          :PersonalID,
          :data_source_id
        ],
        class_name: model_name,
        autosave: false,
      }
      return h
    end

    def self.hud_assoc(col, model_name)
      bipartite_keys col, model_name
    end

    def self.hud_key=(key)
      @hud_key = key
    end

    def self.hud_key
      @hud_key
    end

    def self.related_item_keys
      []
    end

  end
end