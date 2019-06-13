module Bo
  class Config < GrdaWarehouseBase
    self.table_name = :bo_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY']

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name

  end
end