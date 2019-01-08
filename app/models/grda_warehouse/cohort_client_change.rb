module GrdaWarehouse
  class CohortClientChange < GrdaWarehouseBase
    belongs_to :cohort
    belongs_to :cohort_client, -> { with_deleted }
    has_one :client, through: :cohort_client
    belongs_to :user

    validates_presence_of :cohort_client, :cohort, :user, :change

    scope :on_cohort_between, -> (start_date:, end_date:) do
      where("cohort_client_changes.id in (SELECT cc.id
        FROM
        (SELECT *
            FROM cohort_client_changes
            WHERE change IN ('create', 'activate')
        ) cc
        LEFT JOIN LATERAL
        (SELECT *
        FROM cohort_client_changes
        WHERE change IN ('destroy', 'deactivate')
        AND cc.cohort_client_id = cohort_client_id
        AND cc.cohort_id = cohort_id
        AND cc.changed_at < changed_at
        ORDER BY changed_at ASC 
        LIMIT 1) cc_ex ON TRUE
        WHERE (cc_ex.changed_at >= ? OR cc_ex IS NULL) AND cc.changed_at <= ?
        AND (cc_ex.reason IS NULL OR cc_ex.reason != 'Mistake'))", start_date, end_date)
    end

    scope :on_cohort, -> (cohort_id) do
      where(cohort_id: cohort_id)
    end

    scope :removal, -> do
      where(change: ['destroy', 'deactivate'])
    end

    # has_one :cohort_exit, -> { where("id > " ).order(id: :asc) }, class_name: GrdaWarehouse::CohortClientChange.name, primary_key: [:cohort_id, :cohort_client_id], foreign_key: [:cohort_id, :cohort_client_id]
     
    def associated_exit
      a_t = self.class.arel_table
      self.class.removal.
        where(
          cohort_id: cohort_id, 
          cohort_client_id: cohort_client_id
        ).
        where(a_t[:id].gt(id)).
        order(id: :asc).
        limit(1).first
    end

    def change_reason
      return reason if reason.present?
      if change == 'deactivate'
        return 'Deactivated'
      end
    end
  end
end