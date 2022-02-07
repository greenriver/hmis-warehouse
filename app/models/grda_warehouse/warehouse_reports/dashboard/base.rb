###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard
  class Base < GrdaWarehouse::WarehouseReports::Base
    attr_accessor :user
    include AvailableSubPopulations
    include ArelHelper

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user))
    end

    def homeless_service_history_source
      scope = service_history_source.
        homeless
      history_scope(scope)
    end

    # def service_counts project_type
    #   homeless_service_history_source.
    #   service_within_date_range(start_date: @range.start, end_date: @range.end).
    #   where(service_history_source.project_type_column => project_type).
    #   group(:client_id).
    #   count
    # end

    def service_scope(project_type)
      homeless_service_history_source.
        with_service_between(start_date: @range.start, end_date: @range.end).
        open_between(start_date: @range.start, end_date: @range.end).
        in_project_type(project_type)
    end

    def enrollment_counts(project_type)
      service_scope(project_type).
        group(:client_id).
        select(nf('DISTINCT', [ct(she_t[:enrollment_group_id], '_', she_t[:data_source_id], '_', she_t[:project_id])]).to_sql).
        count
    end

    def entry_counts(project_type)
      service_scope(project_type).
        started_between(start_date: @range.start, end_date: @range.end).
        group(:client_id).
        select(nf('DISTINCT', [ct(she_t[:enrollment_group_id], '_', she_t[:data_source_id], '_', she_t[:project_id])]).to_sql).
        count
    end

    def entry_dates_by_client(project_type)
      @entry_dates_by_client = {}
      # limit to clients with an entry within the range and service within the range in the type
      involved_client_ids = homeless_service_history_source.
        entry.
        started_between(start_date: @range.start, end_date: @range.end).
        in_project_type(project_type).
        with_service_between(start_date: @range.start, end_date: @range.end).
        distinct.
        select(:client_id)
      # get all of their entry records regardless of date range
      homeless_service_history_source.
        entry.
        where(client_id: involved_client_ids).
        where(she_t[:first_date_in_program].lteq(@range.end)).
        in_project_type(project_type).
        order(first_date_in_program: :desc).
        pluck(:client_id, :first_date_in_program).
      each do |client_id, first_date_in_program|
        @entry_dates_by_client[client_id] ||= []
        @entry_dates_by_client[client_id] << first_date_in_program
      end
      @entry_dates_by_client
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        where(client_id: client_source.distinct.select(:id))
    end

    def service_history_columns
      {
        client_id: she_t[:client_id].as('client_id').to_sql,
        project_id: she_t[:project_id].as('project_id').to_sql,
        first_date_in_program: she_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: she_t[:last_date_in_program].as('last_date_in_program').to_sql,
        project_name: she_t[:project_name].as('project_name').to_sql,
        project_type: she_t[service_history_source.project_type_column].as('project_type').to_sql,
        organization_id: she_t[:organization_id].as('organization_id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
      }
    end

    def colorize(object)
      # make a hash of the object, truncate it to an appropriate size and then turn it into
      # a css friendly hash code
      "#%06x" % (Zlib::crc32(Marshal.dump(object)) & 0xffffff)
    end

    def run_and_save!
      self.started_at = DateTime.now
      self.parameters = self.class.params
      self.data = run!
      self.finished_at = DateTime.now
      save
    end
  end
end
