module HmisExternalApis
  module AcHmis
    def self.data_source
      # Note: not set up to handle multiple HMIS data sources, since ac_hmis doesn't need it. Use the first one.
      ::GrdaWarehouse::DataSource.hmis.order(:id).first!
    end
  end
end
