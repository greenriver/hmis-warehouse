module Reporting
  class Housed < ReportingBase
    self.table_name = :warehouse_houseds
    include ArelHelper
    include TsqlImport

    def populate!
      return unless source_data.present?
      headers = source_data.first.keys
      self.transaction do
        self.class.delete_all
        insert_batch(self.class, headers, source_data.map(&:values))
      end
    end

    def source_data
      @source_data ||= begin
        cache_client = GrdaWarehouse::Hud::Client.new
        enrollment_data.map do |en|
          next unless client = client_details[en[:client_id]]
          client.delete(:id)
          en.merge!(client)
          en[:month_year] = en[:housed_date]&.strftime('%Y-%m-01')
          if HUD.permanent_destinations.include?(en[:destination])
            en[:ph_destination] = :ph
          else
            en[:ph_destination] = :not_ph
          end
          en[:race] = cache_client.race_string(scope_limit: GrdaWarehouse::Hud::Client.where(id: client_ids), destination_id: en[:client_id])
          en
        end
      end
    end

    def enrollment_data
      @enrollment_data ||= begin
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
              and(af_t[:DateDeleted].eq(nil))
            ).
          project(
            she_service[:first_date_in_program].as('search_start'),
            she_service[:last_date_in_program].as('search_end'),
            she_residential[:first_date_in_program].as('housed_date'),
            she_residential[:last_date_in_program].as('housing_exit'),
            she_residential[:computed_project_type].as('project_type'),
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
              and(e_t[:DateDeleted].eq(nil))
            ).
          project(
            e_t[:EntryDate].as('search_start'),
            e_t[:MoveInDate].as('search_end'),
            e_t[:MoveInDate].as('housed_date'),
            she_t[:last_date_in_program].as('housing_exit'),
            she_t[:computed_project_type].as('project_type'),
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
              and(e_t[:DateDeleted].eq(nil))
            ).
          project(
            e_t[:EntryDate].as('search_start'),
            e_t[:EntryDate].as('search_end'),
            e_t[:EntryDate].as('housed_date'),
            she_t[:last_date_in_program].as('housing_exit'),
            she_t[:computed_project_type].as('project_type'),
            she_t[:destination],
            she_t[:project_name].as('service_project'),
            she_t[:project_name].as('residential_project'),
            she_t[:client_id],
            "'ph-or-psh' as source"
          )
        query = unionize([enrollment_based.distinct, move_in_based.distinct, ph_based.distinct])
        results = GrdaWarehouseBase.connection.exec_query(query.to_sql)
        keys = results.columns.map(&:to_sym)
        results.cast_values.map do |row|
          Hash[keys.zip(row)]
        end
      end
    end

    def client_ids
      @client_ids ||= enrollment_data.map{|m| m[:client_id]}.uniq
    end

    def client_columns
      {
        id: :id,
        # FirstName: :first_name,
        # LastName: :last_name,
        # SSN: :ssn,
        DOB: :dob,
        Ethnicity: :ethnicity,
        Gender: :gender,
        VeteranStatus: :veteran_status,
      }
    end

    def client_details
      @client_details ||= begin
        GrdaWarehouse::Hud::Client.where(id: client_ids).
          pluck(*client_columns.keys).map do |row|
            Hash[client_columns.values.zip(row)]
          end.index_by{|m| m[:id]}
      end
    end

  end
end