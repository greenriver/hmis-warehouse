require 'test_helper'

# test for GrdaWarehouse::Tasks::CensusImport logic
class CensusImportTest < ActiveSupport::TestCase

  def test_history_for_range_by_project
    assert_equal census.count, sum_over_all_projects, 'code used to pick individuals on day matches census rollup for day'
  end

  def test_history_for_range_by_project_type
    count_per_project_type.each do |type, count|
      scope = service_history_scope.where( project_type: type )
      found = Censuses::CensusByProjectType.new.for_date( big_day, scope: scope ).count
      assert_equal count, found, "got expected number of clients for project type #{type}"
    end
  end

  private

    # find the day with the most service histories in the test database
    def big_day
      @big_day ||= begin
        at = Arel::Table.new 'a'
        sht = service_history.arel_table
        t = at.
          project(at[:date]).
          from(
            sht.
              project(sht[:date]).
              group(sht[:date]).
              order( sht[:id].count.to_sql + ' DESC' ).
              take(1).
              as('a')
          )
          Date.parse sht.engine.connection.select_rows(t.to_sql).first.first
      end
    end

    def start_date
      big_day
    end

    def end_date
      big_day + 1.day
    end

    def rolled_up_by_project
      @rolled_up_by_project ||= importer.history_for_range_by_project( start_date, end_date ).map do |args|
        [ :date, :data_source_id, :project_id, :organization_id, :gender, :vet_status, :count ].zip(args).to_h
      end
    end

    def rolled_up_by_project_type
      @rolled_up_by_project_type ||= importer.history_for_range_by_project_type( start_date, end_date ).map do |args|
        [ :date, :project_type, :vet_status, :gender, :count ].zip(args).to_h
      end
    end

    def service_history
      GrdaWarehouse::ServiceHistory
    end

    def importer
      GrdaWarehouse::Tasks::CensusImport.new
    end

    def sum_over_all_projects
      sum_of_hashes rolled_up_by_project
    end

    def sum_of_hashes(hashes)
      hashes.map{ |h| h[:count] }.map(&:to_i).sum
    end

    def count_per_project_type
      rolled_up_by_project_type.group_by{ |h| h[:project_type] }.map{ |k,v| [ k.to_i, sum_of_hashes(v) ] }.to_h
    end

    def census
      @census ||= begin
        c = Censuses::CensusByProgram.new
        c.for_date big_day, scope: service_history_scope, constraint: -> (h) { h.slice *%w( client_id ProjectName ProjectID ) }
      end
    end

    def service_history_scope
      service_history.service.where.not project_type: nil
    end
end
