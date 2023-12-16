module PerformanceMeasurement
  class EquityReportBuilder
    include ActiveModel::Model

    validates :metric, presence: true
    validates :investigate_by, presence: true

    attr_reader :report, :params

    CHART_DATA_KEY_TO_CLASS = {
      default: PerformanceMeasurement::EquityReportData,
      race: PerformanceMeasurement::EquityReportRaceData,
      age: PerformanceMeasurement::EquityReportAgeData,
      gender: PerformanceMeasurement::EquityReportGenderData,
      household_type: PerformanceMeasurement::EquityReportHouseholdTypeData,
    }.freeze

    def initialize(params, report)
      @report = report
      @params = params || { view_data_by: 'percentage' }
      @chart_data = chart_data_class.new(self)
    end

    def chart_data_class
      CHART_DATA_KEY_TO_CLASS[investigate_by_key]
    end

    def investigate_by_key
      key = (investigate_by || '').gsub(/[[:space:]]/, '').underscore.to_sym
      CHART_DATA_KEY_TO_CLASS.keys.select { |k| k == key }.first || :default
    end

    def describe_filters
      # FIXME
      rslt = "<span>#{metric} by #{investigate_by}</span></br>"
      param_rslt = []
      PerformanceMeasurement::EquityReportData::INVESTIGATE_BY.keys do |key|
        meth = "describe_#{key}".to_sym
        param_rslt.push(send(meth))
      end
      rslt += param_rslt.reject(&:blank?).join(', ')
      # if @params[:project].present?
      #   # FIXME: needs real data
      #   project_name = project_options.select { |p| p.last.to_s == @params[:project] }.first.first
      #   rslt = "#{rslt}, Project #{project_name}"
      # end
      # if @params[:project_type].present?
      #   # FIXME: needs real data
      #   project_type = project_type_options.select { |p| p.last.to_s == @params[:project_type] }.first.first
      #   rslt = "#{rslt}, Project Type #{project_type}"
      # end
      rslt
    end

    def chart_data
      {
        chart_height: @chart_data.chart_height,
        data: @chart_data.data,
      }
    end

    def metric
      @params[:metric]
    end

    def investigate_by
      @params[:investigate_by]
    end

    def race
      @params[:race]&.reject(&:blank?) || []
    end

    def describe_race
      names = race.map do |key|
        PerformanceMeasurement::EquityReportData::RACES[key]
      end.reject(&:blank?).join(', ')
      race.any? ? "Race: #{names}" : ''
    end

    def age
      @params[:age]&.reject(&:blank?) || []
    end

    def describe_age
      names = PerformanceMeasurement::EquityReportData::AGES.select { |_, v| age.map(&:to_sym).include?(v) }.keys.join(', ')
      age.any? ? "Age: #{names}" : ''
    end

    def gender
      @params[:gender]&.reject(&:blank?) || []
    end

    def describe_gender
      names = gender.map { |id| PerformanceMeasurement::EquityReportData::GENDERS[id.to_i] }.reject(&:blank?).join(', ')
      gender.any? ? "Gender: #{names}" : ''
    end

    def household_type
      @params[:household_type]&.reject(&:blank?) || []
    end

    def describe_household_type
      # FIXME fake data
      names = household_type.join(', ')
      household_type.any? ? "Household Type: #{names}" : ''
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
      @report.display_order.map do |sub_sections|
        sub_sections.map do |keys|
          keys.keys.map { |key| @report.detail_title_for(key) }
        end
      end.flatten
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
      PerformanceMeasurement::EquityReportData::RACES.to_a
    end

    def age_options
      PerformanceMeasurement::EquityReportData::AGES
    end

    def gender_options
      PerformanceMeasurement::EquityReportData::GENDERS.to_a
    end

    def household_type_options
      PerformanceMeasurement::EquityReportData::HOUSEHOLD_TYPES
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
      # # FIXME real data
      # [
      #   ['Project Type 1', 1],
      #   ['Project Type 2', 2],
      #   ['Project Type 3', 3],
      #   ['Project Type 4', 4],
      #   ['Project Type 5', 5],
      #   ['Project Type 6', 5],
      # ]
      @report.filter.project_type_code_options_for_select
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
