      SELECT cc.id,
      cohort_clients.client_id,
      cc.cohort_client_id,
      cc.cohort_id,
      cc.user_id,
      cc.change AS entry_action,
      cc.changed_at AS entry_date,
      cc_ex.change AS exit_action,
      cc_ex.changed_at AS exit_date,
      cc_ex.reason
     FROM (((( SELECT cohort_client_changes.id,
              cohort_client_changes.cohort_client_id,
              cohort_client_changes.cohort_id,
              cohort_client_changes.user_id,
              cohort_client_changes.change,
              cohort_client_changes.changed_at,
              cohort_client_changes.reason
             FROM cohort_client_changes
            WHERE ((cohort_client_changes.change)::text = ANY (ARRAY[('create'::character varying)::text, ('activate'::character varying)::text]))) cc
       LEFT JOIN LATERAL ( SELECT cohort_client_changes.id,
              cohort_client_changes.cohort_client_id,
              cohort_client_changes.cohort_id,
              cohort_client_changes.user_id,
              cohort_client_changes.change,
              cohort_client_changes.changed_at,
              cohort_client_changes.reason
             FROM cohort_client_changes
            WHERE (((cohort_client_changes.change)::text = ANY (ARRAY[('destroy'::character varying)::text, ('deactivate'::character varying)::text])) AND (cc.cohort_client_id = cohort_client_changes.cohort_client_id) AND (cc.cohort_id = cohort_client_changes.cohort_id) AND (cc.changed_at < cohort_client_changes.changed_at))
            ORDER BY cohort_client_changes.changed_at
           LIMIT 1) cc_ex ON (true))
       JOIN cohort_clients ON ((cc.cohort_client_id = cohort_clients.id)))
       JOIN "Client" ON (((cohort_clients.client_id = "Client".id) AND ("Client"."DateDeleted" IS NULL))))
    WHERE ((cc_ex.reason IS NULL) OR ((cc_ex.reason)::text <> 'Mistake'::text))
    ORDER BY cc.id;
