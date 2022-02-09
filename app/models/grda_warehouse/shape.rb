###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    def self.table_name_prefix
      'shape_'
    end

    def self.geo_collection_hash(records)
      features = records.map do |record|
        {
          "type": "Feature",
          "properties": record.geo_json_properties,
          "geometry": record.geo_hash_geometry,
        }
      end

      {
        "type": "FeatureCollection",
        "features": features
      }
    end

  end
end
