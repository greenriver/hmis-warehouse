module GrdaWarehouse::Grades
  class Missing < Base
    
    def self.grade_from_score score
      g_t = arel_table
      where(
        g_t[:percentage_low].lteq(score.to_i).
        and(g_t[:percentage_high].gteq(score.to_i).or(g_t[:percentage_high].eq(nil)))
      ).
      order(percentage_low: :asc).
      first
    end
  end
end