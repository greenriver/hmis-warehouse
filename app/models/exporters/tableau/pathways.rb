###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Exporters::Tableau::Pathways
  include ArelHelper
  include TableauExport

  module_function

  def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
    # make the recurring boilerplate
    # why is this here? This is used to create the sankey in Tableau (sigmoid)
    path1 = (0..48).to_a
    path2 = 97.step(49, -1).to_a
    t     = -6.0.step(6, 0.25).to_a
    mins  = ['min']  * 49
    maxs  = ['max']  * 49

    boilerplate = (path1 + path2).zip(t + t).zip(mins + maxs).map(&:flatten)
    # get the real data which will be cross-producted with the boilerplate
    data = pathways_common start_date: start_date, end_date: end_date, coc_code: coc_code
    # add boilerplate headers
    headers = [:path, :t, :minmax] + data.shift
    # do the cross product

    if path.present?
      CSV.open path, 'wb', headers: true do |csv|
        export headers, data, boilerplate, csv
      end
      return true
    else
      CSV.generate headers: true do |csv|
        export headers, data, boilerplate, csv
      end
    end
  end

  def export headers, data, boilerplate, csv
    csv << headers
    data.each do |data_row|
      boilerplate.each do |boilerplate_row|
        csv << boilerplate_row + data_row
      end
    end
  end
  # End Module Functions
end
