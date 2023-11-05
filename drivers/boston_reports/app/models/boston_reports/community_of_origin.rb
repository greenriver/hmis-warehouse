###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports
  class CommunityOfOrigin
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_reader :filter, :config

    ZIP_LIMIT = 10

    def initialize(filter)
      @filter = filter
      @config = BostonReports::Config.first_or_create(&:default_colors)
    end

    def self.default_filter_options
      {
        filters: {
        },
      }
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      report_path_array.join('/')
    end

    def percent(numerator:, denominator:)
      return 0 unless numerator&.positive? && denominator&.positive?

      (numerator.to_f / denominator * 100).round
    end

    def multiple_project_types?
      true
    end

    def self.report_path_array
      [
        :boston_reports,
        :warehouse_reports,
        :community_of_origins,
      ]
    end

    def report_path_array
      self.class.report_path_array
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      false
    end

    private def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        add_demographic_disabilities_control_section,
      ]
    end

    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def report_scope(all_project_types: false, include_date_range: true)
      scope = filter.apply(
        report_scope_source,
        report_scope_source,
        all_project_types: all_project_types,
        include_date_range: include_date_range,
      )
      # Limit to the earliest started enrollment overlapping the universe per client
      scope = scope.one_for_column(
        :entry_date,
        source_arel_table: she_t,
        group_on: :client_id,
        direction: :asc,
        scope: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(
          start_date: filter.start_date,
          end_date: filter.end_date,
        ),
      )
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def enrolled_clients
      report_scope
    end

    def enrolled_with_community_of_origin
      enrolled_clients.joins(**state_joins)
    end

    def enrolled_with_community_of_origin_zip
      enrolled_clients.joins(**zip_joins)
    end

    # NOTE, at this time we only have CoCs for my_state, so we don't need to specify that
    def enrolled_with_community_of_origin_my_state
      enrolled_clients.joins(**coc_joins).
        merge(GrdaWarehouse::Place.with_shape_cocs)
    end

    def count_enrolled_with_community_of_origin
      @count_enrolled_with_community_of_origin ||= enrolled_with_community_of_origin.select(:client_id).distinct.count
    end

    def entering_clients
      report_scope.where(entry_date: filter.range)
    end

    def entering_with_community_of_origin
      entering_clients.joins(**state_joins)
    end

    private def state_joins
      { enrollment: [earliest_enrollment_location_history: { place: :shape_state }] }
    end

    private def zip_joins
      { enrollment: [earliest_enrollment_location_history: { place: :shape_zip_code }] }
    end

    private def coc_joins
      { enrollment: { earliest_enrollment_location_history: :place } }
    end

    def across_the_country_data
      @across_the_country_data ||= begin
        percent_of_clients_data = enrolled_with_community_of_origin.group(:state).count.map do |state, count|
          percentage = percent(numerator: count, denominator: count_enrolled_with_community_of_origin)
          {
            name: state,
            count: count,
            total: count_enrolled_with_community_of_origin,
            percent: percentage,
            display_percent: ActiveSupport::NumberHelper.number_to_percentage(percentage, precision: 1, strip_insignificant_zeros: true),
          }
        end
        percent_names = percent_of_clients_data.map { |d| d[:name] }
        GrdaWarehouse::Shape::State.where(name: percent_names).map do |state|
          state.geo_json_properties.merge(percent_of_clients_data.detect { |d| d[:name] == state.name })
        end.sort_by { |d| d[:percent] }.reverse
      end
    end

    def across_my_state_data
      @across_my_state_data ||= enrolled_with_community_of_origin_my_state.group('shape_cocs.cocnum').count.map do |coc_num, count|
        percentage = percent(numerator: count, denominator: count_enrolled_with_community_of_origin)
        {
          name: HudUtility2024.coc_codes(coc_num),
          count: count,
          total: count_enrolled_with_community_of_origin,
          percent: percentage,
          display_percent: ActiveSupport::NumberHelper.number_to_percentage(percentage, precision: 1, strip_insignificant_zeros: true),
        }
      end.sort_by { |d| d[:percent] }.reverse
    end

    def my_state_data
      across_the_country_data.detect { |d| d[:name] == GrdaWarehouse::Shape::State.my_state.first.name }
    end

    private def zip_code_scope
      enrolled_with_community_of_origin.group(:zipcode).count.
        sort_by(&:last).
        reverse # Ensure descending order
    end

    def top_zip_codes_data
      zip_code_scope.first(ZIP_LIMIT).map do |zip, count|
        percentage = percent(numerator: count, denominator: count_enrolled_with_community_of_origin)
        {
          zip_code: zip,
          count: count,
          total: count_enrolled_with_community_of_origin,
          percent: percentage,
          display_percent: ActiveSupport::NumberHelper.number_to_percentage(percentage, precision: 1, strip_insignificant_zeros: true),
        }
      end
    end

    def zip_code_shape_data
      zips = zip_code_scope.first(ZIP_LIMIT).map(&:first)
      GrdaWarehouse::Shape.geo_collection_hash(GrdaWarehouse::Shape::ZipCode.where(zcta5ce10: zips))
    end

    # this is used to generate colors in JavaScript and should not be converted to ranges
    def zip_code_colors
      [
        { color: '#BF216B', range: [0.02] },
        { color: '#F22797', range: [0.02, 0.05] },
        { color: '#F2BC1B', range: [0.05, 0.1] },
        { color: '#F26A1B', range: [0.1, 0.15] },
        { color: '#F5380E', range: [0.15] },
      ]
    end

    # Leaving this here until we are sure we are _not_ building a detail page
    def detail_headers
      # {
      #   'First Name' => ->(cc, download: false) {
      #     if download
      #       CohortColumns::FirstName.new(cohort_client: cc).value(cc)
      #     else
      #       CohortColumns::FirstName.new(cohort_client: cc).display_read_only(filter.user)
      #     end
      #   },
      #   'Last Name' => ->(cc, download: false) {
      #     if download
      #       CohortColumns::LastName.new(cohort_client: cc).value(cc)
      #     else
      #       CohortColumns::LastName.new(cohort_client: cc).display_read_only(filter.user)
      #     end
      #   },
      #   'Race' => ->(cc, download: false) {
      #     CohortColumns::Race.new(cohort_client: cc).display_read_only(filter.user)
      #   },
      #   'Cohort' => ->(cc, download: false) {
      #     cc[filter.cohort_column]
      #   },
      #   voucher_type_instance.title => ->(cc, download: false) {
      #     if download
      #       voucher_type_instance.class.new(cohort_client: cc).value(cc)
      #     else
      #       voucher_type_instance.class.new(cohort_client: cc).display_read_only(filter.user)
      #     end
      #   },
      #   housed_date_instance.title => ->(cc, download: false) {
      #     if download
      #       housed_date_instance.class.new(cohort_client: cc).value(cc)
      #     else
      #       housed_date_instance.class.new(cohort_client: cc).display_read_only(filter.user)
      #     end
      #   },
      # }
    end
  end
end
