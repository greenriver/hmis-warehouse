module GrdaWarehouse::Grades
  class Utilization < Base
    
    def self.grade_from_score score
      g_t = arel_table
      where(
        g_t[:percentage_under_low].lteq(score.to_i).
        and(g_t[:percentage_under_high].gteq(score.to_i)).
        or(
          g_t[:percentage_over_low].lteq(score.to_i).
          and(g_t[:percentage_over_high].gteq(score.to_i))
        ).
        or(
          g_t[:percentage_over_low].lteq(score.to_i).
          and(g_t[:percentage_over_high].eq(nil))
        )
      ).first
    end
  end
end