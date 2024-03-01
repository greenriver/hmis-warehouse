module HmisExternalApis
  module TcHmis
    def self.data_source
      ::GrdaWarehouse::DataSource.hmis.order(:id).first!
    end
  end
end
