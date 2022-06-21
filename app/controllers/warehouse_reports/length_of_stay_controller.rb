###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
          form: render_to_string(partial: 'form', layout: false),
          table: @data,
        }
      else
        render status: 400, partial: 'form', layout: false
      end
    end

    def length_of_stay
      @data = if @filter.valid?
        projects = @filter.organization.projects.viewable_by(current_user).index_by(&:ProjectID)

        enrollments = service_history_enrollment_source.entry.
          open_between(start_date: @filter.start, end_date: @filter.end).
          where(project_id: projects.keys, data_source_id: projects.values.first.data_source_id)

        lengths = Rails.cache.fetch(['length_of_stay_controller', filter_params.to_s], expires_in: 10.minutes) do
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
          project_buckets['average'] = (project_lengths.sum / project_lengths.size.to_f).round
          data << [project.name(current_user), project_buckets]
        end
        data

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
        'average',
      ]
      @filter = if params[:mo].present?
        ::Filters::MonthAndOrganization.new filter_params.merge(user: current_user)
      else
        ::Filters::MonthAndOrganization.new(user: current_user)
      end
    end

    def filter_params
      if params[:mo].present?
        params.require(:mo).
          permit(
            :month,
            :year,
            :org,
          )
      else
        {}
      end
    end
    helper_method :filter_params

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end
