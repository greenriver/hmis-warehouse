require_relative 'sql_server_base'
module LsaSqlServer

  module_function def models_by_filename
    {
      'LSAReport.csv' => LsaSqlServer::LSAReport,
      'LSAHousehold.csv' => LsaSqlServer::LSAHousehold,
      'LSAPerson.csv' => LsaSqlServer::LSAPerson,
      'LSAExit.csv' => LsaSqlServer::LSAExit,
      'LSACalculated.csv' => LsaSqlServer::LSACalculated,
      'Organization.csv' => LsaSqlServer::Organization,
      'Project.csv' => LsaSqlServer::Project,
      'Funder.csv' => LsaSqlServer::Funder,
      'Inventory.csv' => LsaSqlServer::Inventory,
      'Geography.csv' => LsaSqlServer::Geography,
      # 'LSAHDXOnly.csv' => LsaSqlServer::LSAHDXOnly,
    }.freeze
  end

  class LSAReport < SqlServerBase
    self.table_name = :lsa_Report
    include TsqlImport
  end

  class LSAHousehold < SqlServerBase
    self.table_name = :lsa_Household
    include TsqlImport
  end

  class LSAPerson < SqlServerBase
    self.table_name = :lsa_Person
    include TsqlImport
  end

  class LSAExit < SqlServerBase
    self.table_name = :lsa_Exit
    include TsqlImport
  end

  class LSACalculated < SqlServerBase
    self.table_name = :lsa_Calculated
    include TsqlImport
  end

  class Organization < SqlServerBase
    self.table_name = :lsa_Organization
    include TsqlImport
  end

  class Project < SqlServerBase
    self.table_name = :lsa_Project
    include TsqlImport
  end

  class Funder < SqlServerBase
    self.table_name = :lsa_Funder
    include TsqlImport
  end

  class Inventory < SqlServerBase
    self.table_name = :lsa_Inventory
    include TsqlImport
  end

  class Geography < SqlServerBase
    self.table_name = :lsa_Geography
    include TsqlImport
  end

  # class LSAHDXOnly < SqlServerBase
  #   self.table_name = :LSAHDXOnly
  #   include TsqlImport
  # end
end