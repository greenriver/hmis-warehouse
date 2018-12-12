# For now, this only deals with RRH projects
module Reporting
  class Housed < ReportingBase
    self.table_name = :warehouse_houseds
    include ArelHelper
    include TsqlImport

    scope :viewable_by, -> (user) do
      # need to pluck project ids from the warehouse database
      where(project_id: GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id))
    end

    scope :youth, -> do
      where(dob: 24.years.ago..18.years.ago)
    end

    scope :veteran, -> do
      where(veteran_status: 1)
    end

    scope :individual, -> do
      where(presented_as_individual: true)
    end

    scope :family, -> do
      where(presented_as_individual: false)
    end

    scope :children_only, -> do
      where(children_only: true)
    end

    scope :ph_destinations, -> do
      where(destination: HUD.permanent_destinations)
    end   

    # Pre-placement
    scope :enrolled_pre_placement, ->(start_date:, end_date:) do
      where.not(service_project: 'No Service Enrollment').
      where(
        arel_table[:search_start].lt(end_date).
        and(
          arel_table[:search_end].gt(start_date).
          or(arel_table[:search_end].eq(nil))
        )
      )
    end

    scope :exiting_pre_placement, -> (start_date:, end_date:) do
      where(search_end: start_date..end_date).
      where.not(service_project: 'No Service Enrollment')
    end

    scope :entering_pre_placement, -> (start_date:, end_date:) do
      where(search_start: start_date..end_date).
      where.not(service_project: 'No Service Enrollment')
    end

    scope :stayers_pre_placement, -> (start_date:, end_date:) do
      where(client_id: enrolled_pre_placement(start_date: start_date, end_date: end_date).select(:client_id)).
      where.not(client_id: exiting_pre_placement(start_date: start_date, end_date: end_date).select(:client_id))
    end

    scope :leavers_pre_placement, -> (start_date:, end_date:) do
      enrolled_pre_placement(start_date: start_date, end_date: end_date).
      exiting_pre_placement(start_date: start_date, end_date: end_date)
    end

    # Stabilization
    scope :enrolled_stabilization, ->(start_date:, end_date:) do
      where(
        arel_table[:housed_date].lt(end_date).
        and(
          arel_table[:housing_exit].gt(start_date).
          or(arel_table[:housing_exit].eq(nil))
        )
      )
    end

    scope :exiting_stabilization, -> (start_date:, end_date:) do
      where(housing_exit: start_date..end_date)
    end

    scope :entering_stabilization, -> (start_date:, end_date:) do
      where(housed_date: start_date..end_date)
    end

    scope :stayers_stabilization, -> (start_date:, end_date:) do
      where(client_id: enrolled_stabilization(start_date: start_date, end_date: end_date).select(:client_id)).
      where.not(client_id: exiting_stabilization(start_date: start_date, end_date: end_date).select(:client_id))
    end

    scope :leavers_stabilization, -> (start_date:, end_date:) do
      enrolled_stabilization(start_date: start_date, end_date: end_date).
      exiting_stabilization(start_date: start_date, end_date: end_date)
    end

    # Combined
    scope :enrolled, -> (start_date:, end_date:) do
      where(
        arel_table[:client_id].in(
          Arel::Nodes::SqlLiteral.new(enrolled_pre_placement(start_date: start_date, end_date: end_date).
          distinct.
          select(:client_id).to_sql)
        ).
        or(
          arel_table[:client_id].in(
            Arel::Nodes::SqlLiteral.new(enrolled_stabilization(start_date: start_date, end_date: end_date).
            distinct.
            select(:client_id).to_sql)
          )
        )
      )
    end

    scope :stayers, -> (start_date:, end_date:) do
      enrolled(start_date: start_date, end_date: end_date).
      where(
        arel_table[:housing_exit].gt(end_date).
          or(arel_table[:housing_exit].eq(nil))
      )
    end

    scope :leavers, -> (start_date:, end_date:) do
      enrolled(start_date: start_date, end_date: end_date).
      where(arel_table[:housing_exit].lteq(end_date))
    end


    def self.available_subpopulations
      {
        youth: 'Youth',
        veteran: 'Veteran',
      }
    end

    def self.available_household_types
      {
        individual: 'Individuals',
        family: 'Families',
        children_only: 'Children only',
      }
    end

    def self.subpopulation(key)
      if available_subpopulations[key].present?
        key
      else
        :current_scope
      end
    end

    def self.household_type(key)
      if available_household_types[key].present?
        key
      else
        :current_scope
      end
    end

    def populate!
      cache_client = GrdaWarehouse::Hud::Client.new
      data = enrollment_data.map do |en|
        client = client_details[en[:client_id]]
        next unless client.present?
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
      headers = data.first.keys

      self.transaction do
        self.class.delete_all
        insert_batch(self.class, headers, data.map(&:values))
      end
    end

    def two_project_ids
      @two_project_ids ||= affiliated_projects.keys
    end

    def one_project_ids
      one_project_ids = GrdaWarehouse::Hud::Project.rrh.
        where.not(id: two_project_ids).
        distinct.
        pluck(:id)
    end

    def lookback_date
      '2016-01-01'.to_date
    end

    def enrollment_data
      one_project_data + two_project_data
    end

    def default_row
      @default_row ||= {
        search_start: nil,
        search_end: nil,
        housed_date: nil,
        housing_exit: nil,
        project_type: nil,
        destination: nil,
        service_project: nil,
        residential_project: nil,
        client_id: nil,
        presented_as_individual: nil,
        children_only: nil,
        individual_adult: nil,
        dob: nil,
        race: nil,
        ethnicity: nil,
        veteran_status: nil,
        month_year: nil,
        ph_destination: nil,
        project_id: nil,
      }
    end

    # fetch residential RRH data
    # fetch all enrollments for associated pre-placement enrollments
    # comparing by client_id, loop over rrh data and add pre-placement data for record immediately preceding
    # 
    def two_project_data
      @two_project_data ||= begin
        processed_service_enrollments = Set.new
        from_residential_enrollments = two_project_residential_data.map do |residential_enrollment|
          key = [
            residential_enrollment[:client_id],
            residential_enrollment[:residential_project_id],
          ]
          en = default_row.merge(residential_enrollment.slice(*default_row.keys))
          en[:project_id] = residential_enrollment[:residential_project_id]
          service_enrollments_for_client = two_project_service_data[key]
          if service_enrollments_for_client.present?
            related_service_enrollment = service_enrollments_for_client.select do |ser_en|
              ser_en[:search_start] <= en[:housed_date]
            end.first
            if related_service_enrollment
              processed_service_enrollments << related_service_enrollment[:enrollment_id]
              en[:search_start] = related_service_enrollment[:search_start]
              en[:search_end] = related_service_enrollment[:search_end]
              en[:service_project] = related_service_enrollment[:service_project]
            else
              en[:search_start] = residential_enrollment[:housed_date]
              en[:search_end] = residential_enrollment[:housed_date]
              en[:service_project] = 'No Service Enrollment'
            end
          else
            en[:search_start] = residential_enrollment[:housed_date]
            en[:search_end] = residential_enrollment[:housed_date]
            en[:service_project] = 'No Service Enrollment'
          end
          en[:source] = 'enrollment_based'
          en
        end

        from_service_enrollments = two_project_service_data.values.flatten(1).map do |ser_en|
          next if processed_service_enrollments.include? ser_en[:enrollment_id]
          ser_en[:project_id] = residential_project_id_for(ser_en[:service_project_id])
          en = default_row.merge(ser_en.slice(*default_row.keys))
          en[:source] = 'enrollment_based'
          en
        end.compact

        from_residential_enrollments + from_service_enrollments
      end
    end

    def two_project_residential_data
      @two_project_residential_data ||= begin
        GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:project, :enrollment, :client).
        merge(GrdaWarehouse::Hud::Project.where(id: two_project_ids)).
        where(
          she_t[:first_date_in_program].lt(Date.today).
          and(
            she_t[:last_date_in_program].gt(lookback_date).
            or(she_t[:last_date_in_program].eq(nil))
          )
        ).
        pluck(*two_project_residential_columns.values).
        map do |row|
          Hash[two_project_residential_columns.keys.zip(row)]
        end
      end
    end

    def two_project_residential_columns
      @two_project_residential_columns ||= {
        residential_project_id: p_t[:id].as('residential_project_id').to_sql,
        housed_date: she_t[:first_date_in_program].as('housed_date').to_sql,
        housing_exit: she_t[:last_date_in_program].to_sql,
        project_type: she_t[GrdaWarehouse::ServiceHistoryEnrollment.project_type_column].to_sql,
        destination: she_t[:destination].to_sql,
        residential_project: she_t[:project_name].as('residential_project').to_sql,
        client_id: she_t[:client_id].to_sql,
        presented_as_individual: she_t[:presented_as_individual].to_sql,
        children_only: she_t[:children_only].to_sql,
        individual_adult: she_t[:individual_adult].to_sql,
        project_id: p_t[:id].to_sql,
      }
    end

    def two_project_service_data
      @two_project_service_data ||= begin
        GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:project, :enrollment, :client).
        merge(GrdaWarehouse::Hud::Project.where(id: affiliated_projects.values)).
        where(
          she_t[:first_date_in_program].lt(Date.today).
          and(
            she_t[:last_date_in_program].gt(lookback_date).
            or(she_t[:last_date_in_program].eq(nil))
          )
        ).
        order(she_t[:first_date_in_program].desc).
        pluck(*two_project_service_columns.values).
        map do |row|
          Hash[two_project_service_columns.keys.zip(row)]
        end.group_by do |row|
          [
            row[:client_id],
            residential_project_id_for(row[:service_project_id]),
          ]
        end
      end
    end

    def residential_project_id_for service_project_id
      @inverse_affiliated_projects ||= affiliated_projects.invert
      @inverse_affiliated_projects[service_project_id]
    end

    def two_project_service_columns
      @two_project_service_columns ||= {
        service_project_id: p_t[:id].to_sql,
        search_start: she_t[:first_date_in_program].to_sql,
        search_end: she_t[:last_date_in_program].as('search_end').to_sql,
        service_project: she_t[:project_name].as('service_project').to_sql,
        client_id: she_t[:client_id].to_sql,
        enrollment_id: she_t[:id].to_sql,
      }
    end

    def affiliation_columns
      @affiliation_columns ||= {
        p_id: p_t[:id].to_sql, 
        res_id: :ResProjectID,
        ser_id: :ProjectID,
        data_source_id: :data_source_id,
      }
    end

    # Lookup for residential and service only projects in the form
    # { residential_project_id: service_project_id }
    def affiliated_projects
      @affiliated_projects ||= begin
        residential_projects = GrdaWarehouse::Hud::Affiliation.
          joins(:residential_project).
          merge(GrdaWarehouse::Hud::Project.rrh).
          pluck(*affiliation_columns.values).map do |row|
            Hash[affiliation_columns.keys.zip(row)]
          end

        service_projects = GrdaWarehouse::Hud::Affiliation.
          joins(:project).
          pluck(*affiliation_columns.values).map do |row|
            Hash[affiliation_columns.keys.zip(row)]
          end.index_by do |row|
            [
              row[:data_source_id],
              row[:res_id],
            ]
          end

        residential_projects.map do |residential_project|
          key = [
            residential_project[:data_source_id],
            residential_project[:res_id],
          ]
          service_project = service_projects[key]
          [
            residential_project[:p_id],
            service_project[:p_id],
          ]
        end.to_h
      end
    end

    def one_project_data
      @one_project_data ||= begin
      GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:project, :enrollment, :client).
        merge(GrdaWarehouse::Hud::Project.where(id: one_project_ids)).
        where(
          she_t[:first_date_in_program].lt(Date.today).
          and(
            she_t[:last_date_in_program].gt(lookback_date).
            or(she_t[:last_date_in_program].eq(nil))
          )
        ).
        pluck(*one_project_columns.values).
        map do |row|
          residential_enrollment = Hash[one_project_columns.keys.zip(row)]
          # if exit but no move-in-date, set search end to exit and blank exit, no stabilization, only pre-placement
          if residential_enrollment[:housing_exit].present? && residential_enrollment[:search_end].blank?
            residential_enrollment[:search_end] = residential_enrollment[:housing_exit]
            residential_enrollment[:housing_exit] = nil
          end
          residential_enrollment[:source] = 'move-in-date'
          en = default_row.merge(residential_enrollment)
          en
        end
      end
    end

    def one_project_columns
      @one_project_columns ||= {
        search_start: she_t[:first_date_in_program].to_sql,
        search_end: e_t[:MoveInDate].as('search_end').to_sql,
        housed_date: e_t[:MoveInDate].as('housed_date').to_sql,
        housing_exit: she_t[:last_date_in_program].to_sql,
        project_type: she_t[GrdaWarehouse::ServiceHistoryEnrollment.project_type_column].to_sql,
        destination: she_t[:destination].to_sql,
        service_project: she_t[:project_name].as('service_project').to_sql,
        residential_project: she_t[:project_name].as('residential_project').to_sql,
        client_id: she_t[:client_id].to_sql,
        presented_as_individual: she_t[:presented_as_individual].to_sql,
        children_only: she_t[:children_only].to_sql,
        individual_adult: she_t[:individual_adult].to_sql,
        project_id: p_t[:id].to_sql,
      }
    end

    # def populate!
    #   return unless source_data.present?
    #   headers = source_data.first.keys
    #   self.transaction do
    #     self.class.delete_all
    #     insert_batch(self.class, headers, source_data.map(&:values))
    #   end
    # end

    # def source_data
    #   @source_data ||= begin
    #     cache_client = GrdaWarehouse::Hud::Client.new
    #     enrollment_data.map do |en|
    #       next unless client = client_details[en[:client_id]]
    #       client.delete(:id)
    #       en.merge!(client)
    #       en[:month_year] = en[:housed_date]&.strftime('%Y-%m-01')
    #       if HUD.permanent_destinations.include?(en[:destination])
    #         en[:ph_destination] = :ph
    #       else
    #         en[:ph_destination] = :not_ph
    #       end
    #       en[:race] = cache_client.race_string(scope_limit: GrdaWarehouse::Hud::Client.where(id: client_ids), destination_id: en[:client_id])
    #       en
    #     end
    #   end
    # end

    # def enrollment_data
    #   @enrollment_data ||= begin
    #     she_residential = Arel::Table.new(she_t.table_name)
    #     she_residential.table_alias = 'residential_enrollment'

    #     she_service = Arel::Table.new(she_t.table_name)
    #     she_service.table_alias = 'service_enrollment'

    #     enrollment_based = she_service.
    #       join(af_t).on(she_service[:data_source_id].eq(af_t[:data_source_id]).
    #         and(she_service[:project_id].eq(af_t[:ProjectID]))).
    #       join(she_residential).on(she_service[:client_id].eq(she_residential[:client_id])).
    #       join(p_t).on(she_residential[:project_id].eq(p_t[:ProjectID]).
    #         and(she_residential[:data_source_id].eq(p_t[:data_source_id]).
    #         and(p_t[:DateDeleted].eq(nil))
    #       )).
    #       where(
    #         she_residential[:project_id].eq(af_t[:ResProjectID]).
    #         and(af_t[:DateDeleted].eq(nil))
    #       ).
    #       project(
    #         she_service[:first_date_in_program].as('search_start'),
    #         she_service[:last_date_in_program].as('search_end'),
    #         she_residential[:first_date_in_program].as('housed_date'),
    #         she_residential[:last_date_in_program].as('housing_exit'),
    #         she_residential[:computed_project_type].as('project_type'),
    #         she_residential[:destination],
    #         she_service[:project_name].as('service_project'),
    #         she_residential[:project_name].as('residential_project'),
    #         she_service[:presented_as_individual].as('presented_as_individual'),
    #         she_service[:children_only].as('children_only'),
    #         she_service[:individual_adult].as('individual_adult'),
    #         she_residential[:client_id],
    #         p_t[:id].as('project_id'),
    #         "'enrollment_based' as source"
    #       )

    #     move_in_based = she_t.
    #       join(e_t).on(
    #           she_t[:enrollment_group_id].eq(e_t[:EnrollmentID]).
    #           and(she_t[:data_source_id].eq(e_t[:data_source_id])).
    #           and(she_t[:project_id].eq(e_t[:ProjectID]))
    #       ).
    #       join(p_t).on(she_t[:project_id].eq(p_t[:ProjectID]).
    #         and(she_t[:data_source_id].eq(p_t[:data_source_id]).
    #         and(p_t[:DateDeleted].eq(nil))
    #       )).
    #       where(
    #           e_t[:MoveInDate].not_eq(nil).
    #           and(e_t[:DateDeleted].eq(nil))
    #         ).
    #       project(
    #         e_t[:EntryDate].as('search_start'),
    #         e_t[:MoveInDate].as('search_end'),
    #         e_t[:MoveInDate].as('housed_date'),
    #         she_t[:last_date_in_program].as('housing_exit'),
    #         she_t[:computed_project_type].as('project_type'),
    #         she_t[:destination],
    #         she_t[:project_name].as('service_project'),
    #         she_t[:project_name].as('residential_project'),
    #         she_t[:presented_as_individual].as('presented_as_individual'),
    #         she_t[:children_only].as('children_only'),
    #         she_t[:individual_adult].as('individual_adult'),
    #         she_t[:client_id],
    #         p_t[:id].as('project_id'),
    #         "'move-in-date' as source"
    #       )

    #     ph_based = she_t.
    #       join(e_t).on(
    #           she_t[:enrollment_group_id].eq(e_t[:EnrollmentID]).
    #           and(she_t[:data_source_id].eq(e_t[:data_source_id])).
    #           and(she_t[:project_id].eq(e_t[:ProjectID]))
    #       ).
    #       join(p_t).on(she_t[:project_id].eq(p_t[:ProjectID]).
    #         and(she_t[:data_source_id].eq(p_t[:data_source_id]).
    #         and(p_t[:DateDeleted].eq(nil))
    #       )).
    #       where(
    #         she_t[:computed_project_type].in([3, 10]).
    #         and(e_t[:DateDeleted].eq(nil))
    #       ).
    #       project(
    #         e_t[:EntryDate].as('search_start'),
    #         e_t[:EntryDate].as('search_end'),
    #         e_t[:EntryDate].as('housed_date'),
    #         she_t[:last_date_in_program].as('housing_exit'),
    #         she_t[:computed_project_type].as('project_type'),
    #         she_t[:destination],
    #         she_t[:project_name].as('service_project'),
    #         she_t[:project_name].as('residential_project'),
    #         she_t[:presented_as_individual].as('presented_as_individual'),
    #         she_t[:children_only].as('children_only'),
    #         she_t[:individual_adult].as('individual_adult'),
    #         she_t[:client_id],
    #         p_t[:id].as('project_id'),
    #         "'ph-or-psh' as source"
    #       )
    #     # Remove ph_based section, deemed not relevant
    #     # query = unionize([enrollment_based.distinct, move_in_based.distinct, ph_based.distinct])
    #     query = unionize([enrollment_based.distinct, move_in_based.distinct])

    #     results = GrdaWarehouseBase.connection.exec_query(query.to_sql)
    #     keys = results.columns.map(&:to_sym)
    #     results.cast_values.map do |row|
    #       Hash[keys.zip(row)]
    #     end.group_by do |row|
    #       [row[:client_id], row[:housing_exit], row[:destination]]
    #     end.map do |_, enrollments|
    #       # Client would enter and exit multiple times and would exit on two different dates, keep first housing exit by date for each client
    #       # group by client_id, housing_exit, destination, keep first (aka index_by)
    #       #
    #       # housed %<>% arrange(client_id, housing_exit, destination) %>% distinct(search_start, search_end, housed_date, client_id, service_project, residential_project, fromLast=FALSE, .keep_all = TRUE)
    #       enrollments.sort_by{|row| row[:housing_exit]}.first
    #     end
    #   end
    # end

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