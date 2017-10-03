module GrdaWarehouse::Export::HMISSixOneOne
  class Export < GrdaWarehouse::Import::HMISSixOneOne::Export
    
    def self.available_period_types
      {
        3 => 'Reporting period',
      }.freeze
    end

    def self.available_directives
      {
        2 => 'Full refresh',
      }.freeze
    end

    def self.available_hash_stati
      {
        1 => 'Unhashed',
        4 => 'SHA-256 (RHY)',
      }.freeze
    end
    
  end
end