###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Exporters::Tableau::PathwaysWithDest
  include ArelHelper
  include TableauExport

  module_function

  def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
    if path.present?
      CSV.open path, 'wb', headers: true do |csv|
        pathways_common(start_date: start_date, end_date: end_date, coc_code: coc_code).each do |row|
          csv << row
        end
      end
      return true
    else
      CSV.generate headers: true do |csv|
        pathways_common(start_date: start_date, end_date: end_date, coc_code: coc_code).each do |row|
          csv << row
        end
      end
    end
  end
  # End Module Functions
end
