###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class StaticSpm < GrdaWarehouseBase
    self.table_name = :pm_coc_static_spms
    acts_as_paranoid

    belongs_to :goal
    KNOWN_SPM_CELLS = {
      '1a' => ['B2'],
      '1b' => ['B2'],
      '2a and 2b' => ['B7'],
      '3.2' => ['C2'],
      '4.1' => ['C2'],
      '4.2' => ['C2'],
      '4.3' => ['C2'],
      '4.4' => ['C2'],
      '4.5' => ['C2'],
      '4.6' => ['C2'],
      '5.1' => ['C4'],
      '7a.1' => ['C2'],
      '7b.1' => ['C2'],
      '7b.2' => ['C2'],
    }.freeze
    KNOWN_SPM_METHODS = KNOWN_SPM_CELLS.map do |table, cells|
      cells.map do |cell|
        [table, cell, "table_#{table.parameterize(separator: '_')}_cell_#{cell.parameterize}"]
      end
    end.flatten(1)
    KNOWN_SPM_METHODS.each do |table, cell, method_name|
      define_method method_name do
        data.dig(table, cell)
      end
      define_method "#{method_name}=" do |value|
        data[table] ||= {}
        data[table][cell] = value
      end
    end
  end
end
