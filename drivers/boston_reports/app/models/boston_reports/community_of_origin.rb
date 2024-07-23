###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
          start: 1.months.ago.to_date,
          end: 1.days.ago.to_date,
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

    def self.allowable_section_types
      ['header_counts'] + available_section_types
    end

    def self.available_section_types
      [
        'across_the_country',
        'top_zip_codes',
      ]
    end

    def section_ready?(_)
      true
    end

    private def cache_key_for_section(section)
      [self.class.name, cache_slug, section]
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
        ).select(:id),
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
      enrolled_clients.
        joins(**location_joins).
        joins(places_distinct_join(places_t).join_sources).
        correlated_exists(GrdaWarehouse::Place.joins(:shape_state), quoted_table_name: ClientLocationHistory::Location.quoted_table_name, column_name: [:lat, :lon], alias_name: :places)
    end

    def enrolled_with_community_of_origin_zip
      enrolled_clients.
        joins(**location_joins).
        joins(places_distinct_join(places_zip_t).join_sources).
        correlated_exists(GrdaWarehouse::Place.joins(:shape_zip_code), quoted_table_name: ClientLocationHistory::Location.quoted_table_name, column_name: [:lat, :lon], alias_name: :places).
        one_for_column(
          :located_on,
          direction: :asc,
          source_arel_table: ClientLocationHistory::Location.arel_table,
          group_on: :enrollment_id,
        )
    end

    # NOTE, at this time we only have CoCs for my_state, so we don't need to specify that
    def enrolled_with_community_of_origin_my_state
      enrolled_clients.
        joins(**location_joins).
        joins(places_distinct_join(places_coc_t).join_sources).
        correlated_exists(GrdaWarehouse::Place.with_shape_cocs, quoted_table_name: ClientLocationHistory::Location.quoted_table_name, column_name: [:lat, :lon], alias_name: :places).
        one_for_column(
          :located_on,
          direction: :asc,
          source_arel_table: ClientLocationHistory::Location.arel_table,
          group_on: :enrollment_id,
        )
    end

    # Resulting SQL is the join to distinct places from below:
    # SELECT
    #   "clh_locations"."lat", "clh_locations"."lon", "service_history_enrollments"."client_id", places.state
    # FROM
    #   "service_history_enrollments"
    #   INNER JOIN "Enrollment" ON "Enrollment"."DateDeleted" IS NULL
    #     AND "Enrollment"."data_source_id" = "service_history_enrollments"."data_source_id"
    #     AND "Enrollment"."EnrollmentID" = "service_history_enrollments"."enrollment_group_id"
    #     AND "Enrollment"."ProjectID" = "service_history_enrollments"."project_id"
    #   INNER JOIN "clh_locations" ON "clh_locations"."enrollment_id" = "Enrollment"."id"

    #   INNER JOIN (select distinct "lat", "lon", "state"
    #   from
    #   "places") places on "clh_locations"."lat" = "places"."lat"
    #         AND "clh_locations"."lon" = "places"."lon"

    # WHERE (EXISTS (
    #     SELECT
    #       1
    #     FROM
    #       "places"
    #       INNER JOIN "shape_states" ON "shape_states"."name" = "places"."state"
    #         AND "clh_locations"."lat" = "places"."lat"
    #         AND "clh_locations"."lon" = "places"."lon"))
    private def places_distinct_join(places_query_table)
      clh_t = ClientLocationHistory::Location.arel_table
      clh_t.join(places_query_table).on(clh_t[:lat].eq(places_query_table[:lat]).and(clh_t[:lon].eq(places_query_table[:lon])))
    end

    def count_enrolled_with_community_of_origin
      @count_enrolled_with_community_of_origin ||= enrolled_with_community_of_origin.select(:client_id).distinct.count
    end

    def entering_clients
      report_scope.where(entry_date: filter.range)
    end

    def entering_with_community_of_origin
      entering_clients.joins(**location_joins)
    end

    private def location_joins
      { enrollment: :direct_enrollment_location_histories }
    end

    private def pla_t
      GrdaWarehouse::Place.arel_table
    end

    private def places_t
      pla_t.project(:lat, :lon, :state).
        distinct.as('places')
    end

    private def places_coc_t
      coc_t = GrdaWarehouse::Shape::Coc.arel_table
      pla_t.project(:lat, :lon, :cocnum).
        # Copied from join in Place
        join(coc_t).on(Arel.sql('ST_Within(ST_SetSRID(ST_Point(places.lon, places.lat), 4326), shape_cocs.geom)')).
        distinct.as('places')
    end

    private def places_zip_t
      pla_t.project(:lat, :lon, :zipcode).
        distinct.as('places')
    end

    def across_the_country_data
      @across_the_country_data ||= Rails.cache.fetch(cache_key_for_section(:across_the_country), expires_in: expiration_length) do
        # Maybe needs a join to place, but a distinct count of :state?
        earliest_for_scope = enrolled_with_community_of_origin.
          one_for_column(
            :located_on,
            direction: :asc,
            source_arel_table: ClientLocationHistory::Location.arel_table,
            group_on: :enrollment_id,
          )
        percent_of_clients_data = earliest_for_scope.group(:state).count.map do |state, count|
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
      # places_coc_t is joined in 'enrolled_with_community_of_origin_my_state' and declares a local table 'places'
      grouping_column = 'places.cocnum'
      @across_my_state_data ||= enrolled_with_community_of_origin_my_state.group(grouping_column).count.map do |coc_num, count|
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
      @zip_code_scope ||= enrolled_with_community_of_origin_zip.group(:zipcode).count.
        sort_by(&:last).
        reverse # Ensure descending order
    end

    def top_zip_codes_data
      @top_zip_codes_data ||= Rails.cache.fetch(cache_key_for_section(:top_zip_codes), expires_in: expiration_length) do
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

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 3.minutes if Rails.env.development?

      30.minutes
    end
  end
end
