module PerformanceMeasurement
  class EquityReportBuilder
    include ActiveModel::Model

    validates :metric, presence: true
    validates :investigate_by, presence: true

    def initialize(params)
      @params = params || { view_data_by: 'percentage' }
    end

    def describe_filters
      rslt = "#{metric} by #{investigate_by}"
      PerformanceMeasurement::FakeEquityAnalysisData::INVESTIGATE_BY.keys.each_with_index do |key, i|
        rslt = "#{rslt}, #{investigate_by_options[i]} #{@params[key]}" if @params[key].present?
      end
      if @params[:project].present?
        # FIXME: needs real data
        project_name = project_options.select { |p| p.last.to_s == @params[:project] }.first.first
        rslt = "#{rslt}, Project #{project_name}"
      end
      if @params[:project_type].present?
        # FIXME: needs real data
        project_type = project_type_options.select { |p| p.last.to_s == @params[:project_type] }.first.first
        rslt = "#{rslt}, Project Type #{project_type}"
      end
      rslt
    end

    def chart_data
      @chart_data ||= PerformanceMeasurement::FakeEquityAnalysisData.new(@params)
      key = (investigate_by || '').
        gsub(/[[:space:]]/, '').
        underscore.to_sym
      # Maybe we need some axis data (view data by), I would like to see how billboard handles it?
      # TODO: Axis may need some work
      {
        chart_height: key.present? ? @chart_data.chart_height(key) : 0,
        data: key.present? ? @chart_data.data(key) : {},
      }
    end

    def metric
      @params[:metric]
    end

    def investigate_by
      @params[:investigate_by]
    end

    def race
      @params[:race]
    end

    def age
      @params[:age]
    end

    def gender
      @params[:gender]
    end

    def household_type
      @params[:household_type]
    end

    def project
      @params[:project]
    end

    def project_type
      @params[:project_type]
    end

    def view_data_by
      @params[:view_data_by]
    end

    def metric_options
      PerformanceMeasurement::FakeEquityAnalysisData::METRICS
    end

    def investigate_by_options
      [
        'Race',
        'Age',
        'Gender',
        'Household Type',
      ]
    end

    def race_options
      PerformanceMeasurement::FakeEquityAnalysisData::RACES
    end

    def age_options
      PerformanceMeasurement::FakeEquityAnalysisData::AGES
    end

    def gender_options
      PerformanceMeasurement::FakeEquityAnalysisData::GENDERS
    end

    def household_type_options
      PerformanceMeasurement::FakeEquityAnalysisData::HOUSEHOLD_TYPES
    end

    def project_options
      # FIXME real data
      [
        ['Project 1', 1],
        ['Project 2', 2],
        ['Project 3', 3],
        ['Project 4', 4],
        ['Project 5', 5],
        ['Project 6', 5],
      ]
    end

    def project_type_options
      # FIXME real data
      [
        ['Project Type 1', 1],
        ['Project Type 2', 2],
        ['Project Type 3', 3],
        ['Project Type 4', 4],
        ['Project Type 5', 5],
        ['Project Type 6', 5],
      ]
    end

    def view_data_by_options
      [
        ['Count', 'count'],
        ['Percentage [Rate, Count]', 'percentage'],
        ['Rate', 'rate'],
      ]
    end
  end
end
