module PerformanceMeasurement::EquityAnalysis
  class Builder
    include ActiveModel::Model

    validates :metric, presence: true
    validates :investigate_by, presence: true

    attr_reader :report, :params

    CHART_DATA_KEY_TO_CLASS = {
      default: PerformanceMeasurement::EquityAnalysis::Data,
      race: PerformanceMeasurement::EquityAnalysis::RaceData,
      age: PerformanceMeasurement::EquityAnalysis::AgeData,
      gender: PerformanceMeasurement::EquityAnalysis::GenderData,
      household_type: PerformanceMeasurement::EquityAnalysis::HouseholdTypeData,
    }.freeze

    VIEW_BY_DEFAULT = 'percentage'.freeze

    def initialize(params, report, user)
      @user = user
      @report = report
      @params = params || { view_data_by: VIEW_BY_DEFAULT }
      @chart_data = chart_data_class.new(self)
    end

    def chart_data_class
      CHART_DATA_KEY_TO_CLASS[investigate_by_key]
    end

    def investigate_by_key
      key = (investigate_by || '').gsub(/[[:space:]]/, '').underscore.to_sym
      CHART_DATA_KEY_TO_CLASS.keys.detect { |k| k == key } || :default
    end

    def describe_filters
      @describe_filters ||= {}.tap do |df|
        variables = []
        variables += PerformanceMeasurement::EquityAnalysis::Data::INVESTIGATE_BY.keys.map do |key|
          send("describe_#{key}".to_sym)
        end
        variables << describe_projects
        variables << describe_project_type
        variables = variables.reject(&:blank?)
        df[:header] = "#{describe_metric} by #{investigate_by}"
        df[:variables] = variables
      end
    end

    def chart_data
      {
        chart_height: @chart_data.chart_height,
        data: @chart_data.data,
      }
    end

    def show_additional_options?
      metric.present? && investigate_by.present?
    end

    def metric
      @params[:metric]&.to_sym
    end

    def describe_metric
      metric_options.detect { |_, sym| sym == metric }.first
    end

    def investigate_by
      @params[:investigate_by]
    end

    def race
      @params[:race]&.reject(&:blank?) || []
    end

    def describe_race
      names = race.map do |key|
        PerformanceMeasurement::EquityAnalysis::Data::RACES[key]
      end.reject(&:blank?).join(', ')
      return unless race.any?

      "Race: #{names}"
    end

    def age
      @params[:age]&.reject(&:blank?) || []
    end

    def describe_age
      names = PerformanceMeasurement::EquityAnalysis::Data::AGES.select { |_, v| age.map(&:to_sym).include?(v) }.keys.join(', ')
      return unless age.any?

      "Age: #{names}"
    end

    def gender
      @params[:gender]&.reject(&:blank?) || []
    end

    def describe_gender
      names = gender.map do |id|
        PerformanceMeasurement::EquityAnalysis::Data::GENDERS[id.to_i]
      end.reject(&:blank?).join(', ')
      return unless gender.any?

      "Gender: #{names}"
    end

    def household_type
      @params[:household_type]&.reject(&:blank?) || []
    end

    def describe_household_type
      names = household_type.map do |id|
        PerformanceMeasurement::EquityAnalysis::Data::HOUSEHOLD_TYPES[id.to_i]
      end.reject(&:blank?).join(', ')
      return unless household_type.any?

      "Household Type: #{names}"
    end

    def project
      @params[:project]&.reject(&:blank?) || []
    end

    def describe_projects
      names = project.map do |d|
        project_options.select { |o| o.last == d.to_i }.first&.first
      end.reject(&:blank?).join(', ')
      return unless project.any?

      "Project: #{names}"
    end

    def project_type
      @params[:project_type]&.reject(&:blank?) || []
    end

    def describe_project_type
      names = project_type.map do |d|
        project_type_options.to_h.select { |_, v| v == d.to_i }.keys.first
      end.reject(&:blank?).join(', ')
      return unless project_type.any?

      "Project Type: #{names}"
    end

    def view_data_by
      @params[:view_data_by] || VIEW_BY_DEFAULT
    end

    def metric_options
      opts = []
      @report.display_order.each do |sub_sections|
        sub_sections.each do |keys|
          keys.keys.each do |key|
            next if key.in?(ignored_metrics)

            opts << [@report.detail_title_for(key), key]
          end
        end
      end
      opts
    end

    private def ignored_metrics
      [
        :overall_average_bed_utilization,
      ].freeze
    end

    def investigate_by_options
      [
        'Race',
        'Age',
        'Gender',
        'Household Type',
      ].freeze
    end

    def race_options
      PerformanceMeasurement::EquityAnalysis::Data::RACES.to_a
    end

    def age_options
      PerformanceMeasurement::EquityAnalysis::Data::AGES
    end

    def gender_options
      PerformanceMeasurement::EquityAnalysis::Data::GENDERS.to_a
    end

    def household_type_options
      PerformanceMeasurement::EquityAnalysis::Data::HOUSEHOLD_TYPES.invert
    end

    def project_options
      return [] if metric.blank?

      result = @report.detail_for(metric)
      return [] if result[:column] == :system

      @report.my_projects(@user, metric).map do |project_id, project_result|
        [project_result.hud_project.name(@user, include_project_type: true), project_id] if project_result.hud_project.present?
      end.compact
    end

    def project_type_options
      return [] if metric.blank?

      available_project_type = @report.projects.joins(:hud_project).distinct.pluck(GrdaWarehouse::Hud::Project.project_type_column)
      @report.filter.project_type_options_for_select(id_limit: available_project_type)
    end

    def view_data_by_options
      [
        ['Count', 'count'],
        ['Percentage', 'percentage'],
        ['Rate', 'rate'],
      ].freeze
    end
  end
end