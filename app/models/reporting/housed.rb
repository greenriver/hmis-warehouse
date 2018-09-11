module Reporting
  class Housed < ReportingBase
    include ArelHelper

    def self.populate
      she_residential = Arel::Table.new(she_t.table_name)
      she_residential.table_alias = 'residential_enrollment'

      she_service = Arel::Table.new(she_t.table_name)
      she_service.table_alias = 'service_enrollment'

      enrollment_based = she_service.
        join(af_t).on(she_service[:data_source_id].eq(af_t[:data_source_id]).
          and(she_service[:project_id].eq(af_t[:ProjectID]))).
        join(she_residential).on(she_service[:client_id].eq(she_residential[:client_id])).
          where(
            she_residential[:project_id].eq(af_t[:ResProjectID]).
            and(af_t[:DateDeleted].not_eq(nil))
          ).
        project(
          she_service[:first_date_in_program].as('search_start'),
          she_service[:last_date_in_program].as('search_end'),
          she_residential[:first_date_in_program].as('housed_date'),
          she_residential[:last_date_in_program].as('housing_exit'),
          she_residential[:destination],
          she_service[:project_name].as('service_project'),
          she_residential[:project_name].as('residential_project'),
          she_residential[:client_id],
          "'enrollment_based' as source"
        )

      move_in_based = she_t.
        join(e_t).on(
            she_t[:enrollment_group_id].eq(e_t[:EnrollmentID]).
            and(she_t[:data_source_id].eq(e_t[:data_source_id])).
            and(she_t[:project_id].eq(e_t[:ProjectID]))
          ).where(
            e_t[:MoveInDate].not_eq(nil).
            and(e_t[:DateDeleted].not_eq(nil))
          ).
        project(
          e_t[:EntryDate].as('search_start'),
          e_t[:MoveInDate].as('search_end'),
          e_t[:MoveInDate].as('housed_date'),
          she_t[:last_date_in_program].as('housing_exit'),
          she_t[:destination],
          she_t[:project_name].as('service_project'),
          she_t[:project_name].as('residential_project'),
          she_t[:client_id],
          "'move-in-date' as source"
        )

      ph_based = she_t.
        join(e_t).on(
            she_t[:enrollment_group_id].eq(e_t[:EnrollmentID]).
            and(she_t[:data_source_id].eq(e_t[:data_source_id])).
            and(she_t[:project_id].eq(e_t[:ProjectID]))
          ).where(
            she_t[:computed_project_type].in([3, 10]).
            and(e_t[:DateDeleted].not_eq(nil))
          ).
        project(
          e_t[:EntryDate].as('search_start'),
          e_t[:EntryDate].as('search_end'),
          e_t[:EntryDate].as('housed_date'),
          she_t[:last_date_in_program].as('housing_exit'),
          she_t[:destination],
          she_t[:project_name].as('service_project'),
          she_t[:project_name].as('residential_project'),
          she_t[:client_id],
          "'ph-or-psh' as source"
        )
      query = unionize([enrollment_based, move_in_based, ph_based])

      summary_data = GrdaWarehouseBase.connection.exec_query(query.to_sql)
    end
  end
end