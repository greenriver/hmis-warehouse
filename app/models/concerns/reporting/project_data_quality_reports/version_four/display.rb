module Reporting::ProjectDataQualityReports::VersionFour::Display
  extend ActiveSupport::Concern
  include ActionView::Helpers
  include ActionView::Context
  included do

    def self.length_of_stay_buckets
      {
          # '0 days' => (0..0),
          # '1 week or less' => (1..6),
          # '1 month or less' => (7..30),
          '1 month or less' => (0..30),
          #'1 to 3 months'  => (31..90),
          #'3 to 6 months' => (91..180),
          '1 to 6 months' => (31..180),
          #'6 to 9 months' => (181..271),
          #'9 to 12 months' => (272..364),
          '6 to 12 months' => (181..364),
          #'1 year to 18 months' => (365..545),
          #'18 months - 2 years' => (546..729),
          #'2 - 5 years' => (730..1825),
          #'5 years or more' => (1826..1.0/0),
          '12 months or greater' => (365..Float::INFINITY),
      }
    end

    def no_clients?
      enrollments.count.zero?
    end

    def no_issues
      'No issues'
    end

    def completeness_goal
      90
    end

    def excess_goal
      105
    end

    def mininum_completeness_threshold
      100 - completeness_goal
    end

    def timeliness_goal
      14 # days
    end

    def income_increase_goal
      75
    end

    def ph_destination_increase_goal
      60
    end

    def enrolled_clients
      enrollments.enrolled
    end

    def enrolled_client_count
      enrolled_clients.count
    end

    def enrolled_household_heads
      enrollments.enrolled.head_of_household
    end

    def enrolled_household_count
      enrolled_household_heads.count
    end

    def active_clients
      enrolled_clients.active
    end

    def active_client_count
      active_clients.count
    end

    def active_households
      enrolled_household_heads.active
    end

    def active_household_count
      active_households.count
    end

    def entering_clients
      enrolled_clients.entered
    end

    def entering_clients_count
      entering_clients.count
    end

    def entering_households
      enrolled_household_heads.entered
    end

    def entering_households_count
      entering_households.count
    end

    def exiting_clients
      enrolled_clients.exited
    end

    def exiting_client_count
      exiting_clients.count
    end

    def exiting_households
      enrolled_household_heads.exited
    end

    def exiting_household_count
      exiting_households.count
    end

    def served_percentages
      @served_percentages ||= begin
        percentages = []
        enrolled = enrolled_clients.group(:project_id).select(:enrolled).count
        active = active_clients.group(:project_id).select(:active).count
        enrolled.each do |id, enrolled_count|
          active_count = active[id] || 0
          percent = (active_count / enrolled_count.to_f) * 100
          if percent < completeness_goal
            percentages << {
              project_id: id,
              project_name: projects.detect{|p| p.id == id}.ProjectName,
              label: 'Percent of enrolled clients with a service in the reporting period below acceptable threshold',
              percent: percent,
            }
          end
        end
        percentages
      end
      return @served_percentages
    end

    def describe_completeness method
      served_percentages = self.send(method)
      if served_percentages.any?
        served_percentages.map do |details|
          content_tag(:li) do
            concat(content_tag(:span, "#{details[:project_name]}: ")) if report_type == :project_group
            concat content_tag(:strong, "#{details[:label]} (#{details[:percent]}%)")
          end
        end.join.html_safe
      else
        no_issues
      end
    end

    def bed_utilization_percentages
      @bed_utilization_percentages ||= begin
        percentages = []
        report_projects.each do |report_project|
          if report_project.average_bed_utilization < completeness_goal
            project = projects.detect{|p| p.id == report_project.project_id}
            percentages << {
              project_id: project.id,
              project_name: project.ProjectName,
              label: 'Bed utilization below acceptable threshold',
              percent: report_project.average_bed_utilization,
            }
          end
        end
        percentages
      end
      return @bed_utilization_percentages
    end

    def unit_utilization_percentages
      @unit_utilization_percentages ||= begin
        percentages = []
        report_projects.each do |report_project|
          if report_project.average_unit_utilization < completeness_goal
            project = projects.detect{|p| p.id == report_project.project_id}
            percentages << {
              project_id: project.id,
              project_name: project.ProjectName,
              label: 'Unit utilization below acceptable threshold',
              percent: report_project.average_unit_utilization,
            }
          end
        end
        percentages
      end
      return @unit_utilization_percentages
    end



  end
end