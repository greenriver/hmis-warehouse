###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::HudCreateLog < GrdaWarehouseBase
  belongs_to :data_source

  def self.to_csv(export_scope=self.all)
    CSV.generate(headers: true) do |csv|
      csv << column_names

      export_scope.pluck(*column_names).each do |row|
        csv << row
      end
    end
  end
end
