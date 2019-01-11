class CreateCohortClientChangesView < ActiveRecord::Migration
  def change
    sql = <<~SQL
      SELECT cc.id, cc.cohort_client_id, cc.cohort_id, cc.user_id, cc.change AS entry_action, cc.changed_at AS entry_date, cc_ex.change AS exit_action, cc_ex.changed_at AS exit_date, cc_ex.reason
      FROM
      (
        SELECT *
          FROM cohort_client_changes
          WHERE change IN ('create', 'activate')
      ) cc
      LEFT JOIN LATERAL
      (
        SELECT *
        FROM cohort_client_changes
        WHERE change IN ('destroy', 'deactivate')
        AND cc.cohort_client_id = cohort_client_id
        AND cc.cohort_id = cohort_id
        AND cc.changed_at < changed_at
        ORDER BY changed_at ASC 
        LIMIT 1
      ) cc_ex ON TRUE
      WHERE (cc_ex.reason IS NULL OR cc_ex.reason != 'Mistake')
      ORDER BY cc.id asc
    SQL

    create_view :combined_cohort_client_changes, sql_definition: sql
  end
end
