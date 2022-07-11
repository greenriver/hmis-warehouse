###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class RunEnrolledDisabledJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(params)
      report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.new
      report.started_at = DateTime.now
      report.parameters = params

      @user = User.find(params[:current_user_id])

      report.user_id = @user.id
      report.parameters[:visible_projects] = if GrdaWarehouse::DataSource.can_see_all_data_sources?(@user)
        [:all, 'All']
      else
        GrdaWarehouse::Hud::Project.viewable_by(@user).pluck(:id, :ProjectName)
      end

      filter_params = params[:filter]

      clients = []
      if filter_params[:disabilities].empty?
        clients = client_source.none
      else
        start_date = filter_params[:start].to_date
        end_date = filter_params[:end].to_date

        enrollment_scope = service_history_enrollment_source.entry.
          open_between(start_date: start_date, end_date: end_date).
          in_project_type(filter_params[:project_types])

        population = service_history_enrollment_source.known_standard_cohorts.detect { |m| m.to_s == filter_params[:sub_population] }
        enrollment_scope = enrollment_scope.send(population) if population.present?

        enrollment_scope = enrollment_scope.heads_of_households if filter_params[:heads_of_household]

        enrollment_scope = enrollment_scope.in_age_ranges(filter_params[:age_ranges])

        clients = client_source.joins(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          merge(GrdaWarehouse::Hud::Disability.where(DisabilityType: filter_params[:disabilities].reject(&:blank?), DisabilityResponse: [1, 2, 3])).
          merge(GrdaWarehouse::Hud::Project.with_project_type(filter_params[:project_types].reject(&:blank?))).
          merge(GrdaWarehouse::Hud::Project.viewable_by(@user)).
          merge(enrollment_scope).
          distinct.
          includes(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          select(*client_columns)
      end
      data = []
      clients.find_each do |client|
        disabilities = client.source_disabilities.map(&:disability_type_text).uniq
        attrs = client.attributes.slice(*client_columns).merge(disabilities: disabilities)

        enrollments = client.source_enrollments.map(&:service_history_enrollment).compact
        enrollment = enrollments.map { |r| r.attributes.compact }.reduce(&:merge)
        data << attrs.merge(enrollment: enrollment)
      end

      report.client_count = clients.size
      report.finished_at = DateTime.now
      report.data = data
      report.save

      NotifyUser.enrolled_disabled_report_finished(params[:current_user_id], report.id).deliver_later(priority: -5)
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def project_source
      GrdaWarehouse::Hud::Project.viewable_by(@user)
    end

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def client_columns
      @client_columns ||= [
        'id',
        'PersonalID',
        'data_source_id',
        'FirstName',
        'LastName',
        'DOB',
        'VeteranStatus',
      ]
    end
  end
end
