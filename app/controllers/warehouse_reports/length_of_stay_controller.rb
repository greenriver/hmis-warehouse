module WarehouseReports
  class LengthOfStayController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :load_mo

    def index
      length_of_stay if request.format.xlsx?
      respond_to :html, :xlsx
    end

    def fetch_length
      if @filter.valid?
        length_of_stay
        render json: {
          form:  render_to_string( partial: 'form', layout: false ),
          table: @data
        }
      else
        render status: 400, partial: 'form', layout: false
      end
    end

    def length_of_stay
      @data = if @filter.valid?
        projects = @filter.organization.projects.index_by(&:ProjectID)
        
        enrollments = service_history_enrollment_source.entry.
          open_between(start_date: @filter.start, end_date: @filter.end).
          where(project_id: projects.keys, data_source_id: projects.values.first.data_source_id)

         
        lengths = Rails.cache.fetch(["length_of_stay_controller", params[:mo].to_s], expires_at: 10.minutes) do
          service_history_service_source.where(service_history_enrollment_id: enrollments.select(:id)).
          where(date: (@filter.start - 3.years..@filter.end)).
          distinct.
          group(:service_history_enrollment_id).
          count(:date)
        end
  
        enrollments = enrollments.group_by(&:project_id)

        data = []
        projects.each do |project_id, project|
          project_buckets = {
            '1 Day to 90 Days' => 0,
            '91 Days to 1 Year' => 0,
            '1 Year to 2 Years' => 0,
            '2 Years to 3 Years' => 0,
            'More than 3 Years' => 0,
          }
          project_lengths = []

          next unless enrollments[project_id].present?
          enrollments[project_id].each do |enrollment|
            count = lengths[enrollment.id] || 0
            project_lengths << count
            bucket = if count <= 90
              '1 Day to 90 Days'
            elsif count <= 362
              '91 Days to 1 Year'
            elsif count <= 365 * 2
              '1 Year to 2 Years'
            elsif count <= 365 * 3
              '2 Years to 3 Years'
            else
              'More than 3 Years'
            end
            project_buckets[bucket] += 1
          end
          project_buckets['average'] = (project_lengths.sum / project_lengths.size.to_f ).round
          data << [project.ProjectName, project_buckets]
        end
        data

        # scope    = @filter.organization.service_histories.service
        # cs_and_egs = scope.
        #   where( st[:date].between( @filter.start..@filter.end ) ).
        #   select( st[:client_id], st[:enrollment_group_id] ).
        #   group( st[:client_id], st[:enrollment_group_id] )
        # cs_and_egs = services.connection.select_rows(cs_and_egs.to_sql).group_by(&:first).map do |cid, rows|
        #   cid = GrdaWarehouse::ServiceHistory.column_types['client_id'].type_cast_from_database(cid)
        #   [
        #     cid,
        #     rows.map(&:last)
        #   ]
        # end
        # make_condition = -> ((cid, egids)) { st[:client_id].eq(cid).and st[:enrollment_group_id].in egids }
        # data = []
        # cs_and_egs.in_groups_of(50) do |stays|
        #   condition = stays.reduce(make_condition.(stays.shift)) do |condition, pair|
        #     condition.or make_condition.(pair)
        #   end
        #   query = scope.where(condition).where( st[:date].lteq @filter.end ).group( st[:client_id], st[:project_id] ).select(
        #     st[:project_id],
        #     st[:client_id],
        #     nf( 'COUNT', [nf('DISTINCT', [st[:date]])] )
        #   )
        #   sql = query.to_sql
        #   data += services.connection.select_rows(query.to_sql)
        # end
        # data = data.group_by(&:first).map do |project_id, rows|
        #   bins = rows.group_by do |*,count|
        #     count = count.to_i
        #     if count <= 90
        #       '1 Day to 90 Days'
        #     elsif count <= 362
        #       '91 Days to 1 Year'
        #     elsif count <= 365 * 2
        #       '1 year to 2 Years'
        #     elsif count <= 365 * 3
        #       '2 Years to 3 Years'
        #     else
        #       'More than 3 Years'
        #     end
        #   end
        #   bins = bins.map{ |k, rs| [ k, rs.size ] }.to_h
        #   @headers.each{ |h| bins[h] ||= 0 }
        #   bins['average'] = ( rows.map(&:last).map(&:to_i).sum / rows.size.to_f ).round
        #   [
        #     project_id,
        #     bins.slice(*@headers)
        #   ]
        # end.to_h
        # projects.each do |id, project|
        #   unless data.has_key? id
        #     data[id] = @headers.map{ |h| [h, 0] }.to_h
        #   end
        # end
        # data.map{ |id,h| [ projects[id].name, h ] }.sort_by(&:first)
      else
        []
      end
    end

    def load_mo
      @headers = [
        '1 Day to 90 Days',
        '91 Days to 1 Year',
        '1 Year to 2 Years',
        '2 Years to 3 Years',
        'More than 3 Years',
        'average'
      ]
      @filter = if params[:mo].present?
        ::Filters::MonthAndOrganization.new params.require(:mo)
      else
        ::Filters::MonthAndOrganization.new
      end
    end

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end

  end
end
