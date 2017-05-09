module WarehouseReports
  class ServiceAfterExitController < ApplicationController
    include ArelHelper

    before_action :require_can_view_reports!
    def index
      services    = GrdaWarehouse::Hud::Service
      enrollments = GrdaWarehouse::Hud::Enrollment
      exits       = GrdaWarehouse::Hud::Exit
      st          = services.arel_table
      et          = enrollments.arel_table
      xt          = exits.arel_table

      # Clients who have Service entries in a program which was previously exited
      subquery = services.joins( enrollment: :exit ).
        select( st[:ProjectEntryID], st[:DateProvided].maximum.as(GrdaWarehouse::Hud::Service.connection.quote_column_name('DateProvided')) ).
        group(st[:ProjectEntryID])
      final_condition = xt[:ExitDate].lt(st[:DateProvided])
      sql = general_query( subquery, final_condition ).to_sql
      @exits = if GrdaWarehouse::Hud::Service.all.engine.postgres?
        result = GrdaWarehouseBase.connection.select_all(sql)
        result.map do |row|
          Hash.new.tap do |hash|
            result.columns.each_with_index.map do |name, idx| 
              hash[name.to_s] = result.send(:column_type, name).type_cast_from_database(row[name])
            end
          end
        end
      else
        GrdaWarehouseBase.connection.raw_connection.execute(sql).each( as: :hash )
      end

      # Clients who have Service entries in a program which hasn't started
      subquery = services.joins(:enrollment).
        select( st[:ProjectEntryID], st[:DateProvided].minimum.as(GrdaWarehouse::Hud::Service.connection.quote_column_name('DateProvided')) ).
        group(st[:ProjectEntryID])
      final_condition = et[:EntryDate].gt(st[:DateProvided])
      sql = general_query( subquery, final_condition ).to_sql
      @exits += if GrdaWarehouse::Hud::Service.all.engine.postgres?
        result = GrdaWarehouseBase.connection.select_all(sql)
        result.map do |row|
          Hash.new.tap do |hash|
            result.columns.each_with_index.map do |name, idx| 
              hash[name.to_s] = result.send(:column_type, name).type_cast_from_database(row[name])
            end
          end
        end
      else
        GrdaWarehouseBase.connection.raw_connection.execute(sql).each( as: :hash )
      end
    end

    private

      def general_query(subquery, final_condition)
        services          = GrdaWarehouse::Hud::Service
        enrollments       = GrdaWarehouse::Hud::Enrollment
        exits             = GrdaWarehouse::Hud::Exit
        clients           = GrdaWarehouse::Hud::Client
        warehouse_clients = GrdaWarehouse::WarehouseClient
        projects          = GrdaWarehouse::Hud::Project

        st = services.arel_table
        et = enrollments.arel_table
        xt = exits.arel_table
        ct = clients.arel_table
        wt = warehouse_clients.arel_table
        pt = projects.arel_table
        sqt = Arel::Table.new 's_group'

        query = services.joins <<-SQL
            INNER JOIN #{subquery.as('s_group').to_sql}
            ON #{
              sqt[:ProjectEntryID].eq(st[:ProjectEntryID]).
              and(st[:DateProvided].eq(sqt[:DateProvided])).
              to_sql
            }
          SQL

        query = query.select(
            st[:ProjectEntryID],
            et[:EntryDate],
            st[:DateProvided],
            xt[:ExitDate],
            xt[:PersonalID],
            xt[:data_source_id],
            ct[:FirstName],
            ct[:LastName],
            wt[:destination_id],
            et[:ProjectID],
            pt[:ProjectName]
          ).
          joins(:client, enrollment: :exit)

        join_condition = wt[:source_id].eq(ct[:id]).to_sql
        query = query.joins("LEFT OUTER JOIN #{wt.engine.quoted_table_name} ON #{join_condition}")

        join_condition = pt[:ProjectID].eq(et[:ProjectID]).and( pt[:data_source_id].eq et[:data_source_id] ).to_sql
        query = query.joins("LEFT OUTER JOIN #{pt.engine.quoted_table_name} ON #{join_condition}")

        query.where(final_condition)
      end
  end
end

=begin

For the record, here are the two raw SQL queries the code above replicates, more or less. The more or less caveat comes
in because the old code did not respect the paranoia columns, so it was aggregating over data that should be regarded as
deleted as well as non-deleted data.

select s.ProjectEntryID, en.EntryDate, s.DateProvided, e.ExitDate, e.PersonalID, e.data_source_id, c.FirstName, c.LastName, wc.destination_id, en.ProjectID, p.ProjectName
from Services s
  inner join (select Services.ProjectEntryID, max(Services.DateProvided) as DateProvided
    from Services, [Exit]
    where Services.ProjectEntryID = [Exit].ProjectEntryID
      and Services.data_source_id = [Exit].data_source_id
    group by Services.ProjectEntryID) s_group
  on s.ProjectEntryID = s_group.ProjectEntryID
  and s.DateProvided = s_group.DateProvided
  inner join [Exit] e on e.ProjectEntryID = s.ProjectEntryID
    and e.data_source_id = s.data_source_id
  inner join Enrollment en on en.ProjectEntryID = s.ProjectEntryID
    and en.data_source_id = s.data_source_id
  inner join Client c on e.PersonalID = c.PersonalID
    and e.data_source_id = c.data_source_id
  left outer join warehouse_clients wc on wc.source_id = c.id
  left outer join Project p on p.ProjectID = en.ProjectID
    and p.data_source_id = en.data_source_id 
where e.ExitDate < s.DateProvided

select s.ProjectEntryID, en.EntryDate, s.DateProvided, e.ExitDate, e.PersonalID, e.data_source_id, c.FirstName, c.LastName, wc.destination_id, en.ProjectID, p.ProjectName
from Services s
  inner join (select Services.ProjectEntryID, min(Services.DateProvided) as DateProvided
    from Services, Enrollment
    where Services.ProjectEntryID = Enrollment.ProjectEntryID
      and Services.data_source_id = Enrollment.data_source_id
    group by Services.ProjectEntryID) s_group
  on s.ProjectEntryID = s_group.ProjectEntryID
  and s.DateProvided = s_group.DateProvided
  inner join [Exit] e on e.ProjectEntryID = s.ProjectEntryID
    and e.data_source_id = s.data_source_id
  inner join Enrollment en on en.ProjectEntryID = s.ProjectEntryID
    and en.data_source_id = s.data_source_id
  inner join Client c on e.PersonalID = c.PersonalID
    and e.data_source_id = c.data_source_id
  left outer join warehouse_clients wc on wc.source_id = c.id
  left outer join Project p on p.ProjectID = en.ProjectID
    and p.data_source_id = en.data_source_id 
where en.EntryDate > s.DateProvided
=end