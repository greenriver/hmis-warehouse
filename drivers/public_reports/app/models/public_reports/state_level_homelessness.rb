###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# require 'get_process_mem'
require 'memery'
module PublicReports
  class StateLevelHomelessness < ::PublicReports::Report
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include Memery
    acts_as_paranoid

    validate :validate_filter_dates_span_one_year, on: :create

    def validate_filter_dates_span_one_year
      return if filter_object.start + 1.years - 1.days <= filter_object.end

      errors.add(:base, 'The start and end dates must span at least one year.')
    end

    MIN_THRESHOLD = 11
    SUPPRESS_TOTALS_AT_OR_BELOW = 100
    # Glossary headings that info icons link to; admins must use these exact headings.
    PROJECT_TYPES_TERM = 'ES / SO / SH / TH'
    UNSHELTERED_TERM = 'Unsheltered / Unsheltered Rate'

    def title
      Translation.translate('State-Level Homelessness Report Generator')
    end

    def yearly?
      settings.iteration_type.to_s == 'year'
    end

    def instance_title
      Translation.translate('State-Level Homelessness Report')
    end

    def raw_layout
      'public_report'
    end

    private def public_s3_directory
      'state-level-homelessness'
    end

    def url
      public_reports_warehouse_reports_state_level_homelessness_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    private def controller_class
      PublicReports::WarehouseReports::StateLevelHomelessnessController
    end

    def publish!
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      self.class.transaction do
        unpublish_similar
        update(
          html: as_html,
          published_url: generate_publish_url, # NOTE this isn't used in this report
          embed_code: generate_embed_code, # NOTE this isn't used in this report
          state: :published,
        )
      end
      push_to_s3
    end

    # Override default push to s3 to enable multiple files
    private def push_to_s3
      bucket = s3_bucket
      sections.each do |section|
        prefix = File.join(public_s3_directory, version_slug.to_s, section.to_s)
        section_html = html_section(section)

        key = File.join(prefix, 'index.html')

        resp = s3_client.put_object(
          acl: 'public-read',
          bucket: bucket,
          key: key,
          body: section_html,
          content_disposition: 'inline',
          content_type: 'text/html',
        )
        if resp.etag
          Rails.logger.info 'Successfully uploaded report file to s3'
        else
          Rails.logger.info 'Unable to upload report file'
        end
      end
    end

    private def remove_from_s3
      bucket = s3_bucket
      prefix = public_s3_directory
      sections.each do |section|
        prefix = File.join(public_s3_directory, version_slug.to_s, section.to_s)
        key = File.join(prefix, 'index.html')
        resp = s3_client.delete_object(
          bucket: bucket,
          key: key,
        )
        if resp.delete_marker
          Rails.logger.info "Successfully removed report file from s3 (#{key})"
        else
          Rails.logger.info "Unable to remove the report file (#{key})"
        end
      end
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    def view_template
      sections
    end

    def generate_publish_url_for(section)
      publish_url = if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}"
      end
      publish_url = if version_slug.present?
        "#{publish_url}/#{version_slug}/#{section}"
      else
        "#{publish_url}/#{section}"
      end
      "#{publish_url}/index.html"
    end

    # The listener sizes the iframe from the height public_report.js posts.
    def generate_embed_code_for(section)
      url = generate_publish_url_for(section)
      frame_id = "public-report-#{id}-#{section}"
      <<~HTML
        <iframe id='#{frame_id}' width='100%' height='400' src='#{url}' frameborder='0' sandbox='allow-scripts'><a href='#{url}'>#{instance_title} -- #{section.to_s.humanize}</a></iframe>
        <script>window.addEventListener('message', function (e) { var f = document.getElementById('#{frame_id}'); if (f && e.source === f.contentWindow && e.data && e.data.type === 'public-report-height' && Number(e.data.height) > 0) f.style.height = Number(e.data.height) + 'px'; });</script>
      HTML
    end

    def sections
      [
        :pit,
        :entering_exiting,
        :summary,
        :map,
        :who,
        :race,
        :raw,
      ].
        freeze
    end

    SCHEMA_VERSION = 2

    private def chart_data
      {
        schema_version: SCHEMA_VERSION,
        data_through: filter_object.end.to_date.iso8601,
        periods: period_labels,
        summary: summary,
        pit_chart: pit_chart,
        inflow_outflow: inflow_outflow,
        who: WhoData.new(self).to_h,
        map: MapData.new(self).to_h,
      }.
        to_json
    end

    def renderable?
      parsed_pre_calculated_data&.dig('schema_version') == SCHEMA_VERSION
    end

    def period_labels
      iteration_dates.map do |date|
        next date.year.to_s if yearly?

        "#{date.year} Q#{((date.month - 1) / 3) + 1}"
      end
    end

    def parsed_pre_calculated_data
      @parsed_pre_calculated_data ||= Oj.load(precalculated_data) if precalculated_data.present?
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def report_scope
      # for compatibility with FilterScopes
      @filter = filter_object
      @project_types = @filter.project_type_numbers
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      # scope = filter_for_range(scope) # all future queries limit this by date further, adding it here just makes it slower
      scope = filter_for_user_access(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope
    end

    # a convenience method to ensure clients all have at least one open homeless enrollment
    # within the report period, and meet all of the other criteria, but not limited by
    # SHE record type
    def homeless_scope
      GrdaWarehouse::ServiceHistoryEnrollment.homeless.
        open_between(start_date: filter_object.start, end_date: filter_object.end).
        where(client_id: report_scope.select(:client_id))
    end

    def iteration_dates
      date = filter_object.start_date
      # force the start to be within the chosen date range
      date = next_iteration(date) if beginning_iteration(date) < date
      dates = []
      while date <= filter_object.end_date
        dates << beginning_iteration(date)
        date = next_iteration(date)
      end
      dates
    end

    private def next_iteration(date)
      return date.next_quarter unless yearly?

      return date.next_year
    end

    def beginning_iteration(date)
      return date.beginning_of_quarter unless yearly?

      return date.beginning_of_year
    end

    def end_iteration(date)
      return date.end_of_quarter unless yearly?

      return [date.end_of_year, filter_object.end_date].min
    end

    private def summary
      date = pit_counts.map(&:first).last
      start_date = date.beginning_of_year
      end_date = [date.end_of_year, filter_object.end_date].min
      scope = homeless_scope.entry.
        with_service_between(
          start_date: start_date,
          end_date: end_date,
        )
      households = scope.heads_of_households.select(:client_id).distinct.count
      homeless_clients = scope.select(:client_id).distinct.count
      unsheltered = scope.hud_project_type(4).select(:client_id).distinct.count
      counts = {
        'homeless_households' => households,
        'homeless_clients' => homeless_clients,
        'unsheltered_clients' => unsheltered,
      }
      {
        year: date.year,
        tiles: [
          { value: enforce_min_threshold(counts, 'homeless_households'), label: 'Homeless Households' },
          { value: enforce_min_threshold(counts, 'homeless_clients'), label: 'People Experiencing Homelessness' },
          { value: enforce_min_threshold(counts, 'unsheltered_percent'), label: 'Unsheltered', term: UNSHELTERED_TERM },
        ],
      }
    end

    # Returns [labels, note]. A label carries a trailing "*" when its PIT
    # year extends beyond the report's end date (a partial year); note
    # explains the asterisk when any label carries one.
    private def year_labels_and_note(dates)
      labels = []
      partial_year_date = nil
      dates.each do |date|
        if date.end_of_year > filter_object.end_date
          labels << "#{date.year}*"
          partial_year_date ||= date
        else
          labels << date.year.to_s
        end
      end
      note = "#{partial_year_date.year} reflects data through #{filter_object.end_date.strftime('%b %-d, %Y')}" if partial_year_date
      [labels, note]
    end

    private def pit_chart
      dates = pit_counts.map(&:first)
      labels, note = year_labels_and_note(dates)
      values = pit_counts.map { |_date, count| enforce_min_threshold(count, 'pit_chart') }
      chart = {
        labels: labels,
        series: [{ label: 'People served in ES, SO, SH, or TH', values: values }],
      }
      chart[:note] = note if note
      chart
    end

    private def inflow_outflow
      dates = inflow_out_flow_counts.map(&:first)
      labels, note = year_labels_and_note(dates)
      ins = inflow_out_flow_counts.map { |_date, in_count, _out_count| enforce_min_threshold(in_count, 'inflow_outflow') }
      outs = inflow_out_flow_counts.map { |_date, _in_count, out_count| enforce_min_threshold(out_count, 'inflow_outflow') }
      chart = {
        labels: labels,
        series: [
          { label: 'People entering ES, SO, SH, or TH (first time homeless)', values: ins },
          { label: 'People exiting ES, SO, SH, or TH to a permanent destination', values: outs },
        ],
      }
      chart[:note] = note if note
      chart
    end

    private def pit_count_dates
      year = filter_object.start.year
      dates = []
      while year < filter_object.end.year + 1
        d = Date.new(year, 1, -1)
        d -= (d.wday - 3) % 7
        dates << d
        year += 1
      end
      dates.select { |date| date.between?(filter_object.start, filter_object.end) }
    end

    private def pit_counts
      pit_count_dates.map do |date|
        start_date = date.beginning_of_year
        end_date = [date.end_of_year, filter_object.end_date].min
        count = homeless_scope.entry.
          with_service_between(
            start_date: start_date,
            end_date: end_date,
          ).
          select(:client_id).
          distinct.
          count
        [
          date,
          count,
        ]
      end
    end
    memoize :pit_counts

    private def inflow_out_flow_counts
      pit_count_dates.map do |date|
        start_date = date.beginning_of_year
        end_date = [date.end_of_year, filter_object.end_date].min
        in_count = homeless_scope.first_date.
          started_between(start_date: start_date, end_date: end_date).
          select(:client_id).
          distinct.
          count
        out_count = homeless_scope.entry.
          exit_within_date_range(start_date: start_date, end_date: end_date).
          where(destination: ::HudHelper.util.permanent_destinations).
          select(:client_id).
          distinct.
          count
        [
          date,
          in_count,
          out_count,
        ]
      end
    end
    memoize :inflow_out_flow_counts

    def published_total(count)
      count.positive? && count <= SUPPRESS_TOTALS_AT_OR_BELOW ? nil : count
    end

    def geography
      @geography ||= Geography.new(settings.map_type)
    end

    def map_svg
      geography.svg
    end

    def map_type_human
      geography.type_human
    end
  end
end
