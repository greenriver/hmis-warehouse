###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImports
  class File < GrdaWarehouseBase
    acts_as_paranoid
    self.table_name = :custom_imports_files
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :user
  end
end
