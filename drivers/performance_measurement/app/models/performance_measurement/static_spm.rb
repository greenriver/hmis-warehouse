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
      '1a' => ['D2', 'G2'],
      '1b' => ['D2', 'G2'],
      '2a and 2b' => ['B7', 'C7', 'E7'],
      # '3.2' => ['C2'], # actually using the PIT counts
      '4.1' => ['C2', 'C3'],
      '4.2' => ['C2', 'C3'],
      '4.3' => ['C2', 'C3'],
      '4.4' => ['C2', 'C3'],
      '4.5' => ['C2', 'C3'],
      '4.6' => ['C2', 'C3'],
      '5.1' => ['C4'],
      '7a.1' => ['C2', 'C3', 'C4'],
      '7b.1' => ['C2', 'C3'],
      '7b.2' => ['C2', 'C3'],
    }.freeze
    KNOWN_SPM_METHODS = KNOWN_SPM_CELLS.map do |table, cells|
      cells.map do |cell|
        [table, cell, "table_#{table.parameterize(separator: '_')}_cell_#{cell.parameterize}"]
      end
    end.flatten(1)
    SPM_METHODS_BY_TABLE_CELL = KNOWN_SPM_METHODS.map do |table, cell, method|
      [[table, cell], method]
    end.to_h.freeze
    KNOWN_SPM_METHODS.each do |table, cell, method_name|
      define_method method_name do
        data.dig(table, cell)&.to_f
      end
      define_method "#{method_name}=" do |value|
        data[table] ||= {}
        data[table][cell] = value
      end
    end

    def data_for(table, cell)
      method = SPM_METHODS_BY_TABLE_CELL[[table, cell]]
      return nil unless method

      public_send(method)
    end
  end
end
