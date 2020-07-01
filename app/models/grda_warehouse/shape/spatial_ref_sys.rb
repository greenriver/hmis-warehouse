module GrdaWarehouse
  module Shape
    class SpatialRefSys < GrdaWarehouseBase
      self.table_name = 'spatial_ref_sys'

      # https://epsg.io/4326
      DEFAULT_SRID = 4326
    end
  end
end
