module GrdaWarehouse::Grades
  class Base < GrdaWarehouseBase
    self.table_name = :grades
    validates_presence_of :grade

    def self.grade_from_score score
      raise 'Implement in sub-class'
    end
  end
end