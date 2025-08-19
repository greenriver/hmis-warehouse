###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaYyaReport
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include Reporting::Status

    def run_and_save!
      start
      create_universe
      report_results
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'MA YYA Report'
    end

    def url
      ma_yya_report_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      previous_period_filter = filter.deep_dup
      previous_period_filter.end = filter.start - 1.day
      previous_period_filter.start = filter.start - 1.year

      previous_period_calculator = UniverseCalculator.new(previous_period_filter)
      previous_period_clients = []
      previous_period_calculator.calculate { |clients| previous_period_clients += clients.values }

      previous_period_client_ids = previous_period_clients.map { |client| client[:client_id] }
      previous_period_followup_clients_ids = find_previous_period_followup_client_ids(previous_period_clients)

      universe_calculator = UniverseCalculator.new(filter)
      universe_calculator.calculate do |clients|
        clients.transform_values do |client|
          client[:reported_previous_period] = previous_period_client_ids.include?(client[:client_id])
          client[:followup_previous_period] = previous_period_followup_clients_ids.include?(client[:client_id])
        end

        Client.import(clients.values)
        universe.add_universe_members(clients)
      end
    end

    private def find_previous_period_followup_client_ids(previous_period_clients)
      previous_period_clients.select do |client|
        client[:subsequent_current_living_situations].count.positive?
      end.map { |client| client[:client_id] }
    end

    private def filter
      @filter ||= ::Filters::FilterBase.new(
        user_id: user_id,
        enforce_one_year_range: false,
      ).update(options)
    end

    def describe_filter_as_html
      filter.describe_filter_as_html(self.class.report_options)
    end

    private def a_t
      MaYyaReport::Client.arel_table
    end

    private def cell_definitions # rubocop:disable Metrics/AbcSize
      report_start_date = filter.start
      report_end_date = filter.end

      # G. Demographics of Rehousing Outcomes: youth who transitioned into stabilized housing (YTD should be unduplicated and match F2a)
      g_population = a_t[:currently_homeless].eq(true).
        and(a_t[:rehoused_on].between(report_start_date..report_end_date))
      {
        A1a: {
          calculation: a_t[:referral_source].eq(7).and(a_t[:currently_homeless].eq(true)),
          label: 'Unduplicated number of outreach contacts with YYA experiencing homelessness',
        },
        A1b: {
          calculation: a_t[:referral_source].eq(7).and(a_t[:at_risk_of_homelessness].eq(true)),
          label: 'Unduplicated number of outreach contacts with YYA considered "at-risk" of homelessness',
        },
        A2a: {
          calculation: a_t[:initial_contact].eq(true).and(a_t[:currently_homeless].eq(true)),
          label: 'Unduplicated number of initial contacts with YYA experiencing homelessness',
        },
        A2b: {
          calculation: a_t[:initial_contact].eq(true).and(a_t[:at_risk_of_homelessness].eq(true)),
          label: 'Unduplicated number of initial contacts with YYA considered "at-risk" of homelessness',
        },
        A3a: {
          calculation: a_t[:entry_date].gteq(filter.start).and(a_t[:at_risk_of_homelessness].eq(true)),
          label: 'Number of YYA completing new intake: YYA considered "at-risk" of homelessness',
        },
        A3b: {
          calculation: a_t[:entry_date].lt(filter.start).and(a_t[:at_risk_of_homelessness].eq(true)),
          label: 'Number of YYA continuing in case management',
        },
        A4a: {
          calculation: a_t[:entry_date].gteq(filter.start).and(a_t[:currently_homeless].eq(true)),
          label: 'Number of YYA completing new intake: YYA experiencing homelessness',
        },
        A4b: {
          calculation: a_t[:entry_date].lt(filter.start).and(a_t[:currently_homeless].eq(true)),
          label: 'Number of YYA continuing in case management',
        },
        D1a: {
          calculation: a_t[:age].lt(18).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who were Under 18',
        },
        D1b: {
          calculation: a_t[:gender].eq(1).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Man',
        },
        D1c: {
          calculation: a_t[:gender].eq(0).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Woman',
        },
        D1d: {
          calculation: a_t[:gender].eq(5).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Transgender',
        },
        D1e: {
          calculation: a_t[:gender].eq(4).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Non-Binary',
        },
        D1f: {
          calculation: a_t[:gender].in([8, 9]).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who  are questioning gender/Client doesn\'t know/Client prefers not to answer.',
        },
        D1g: {
          calculation: a_t[:gender].eq(99).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served with no Gender Data collected',
        },
        D2a: {
          calculation: a_t[:race].eq(5).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as White (race)',
        },
        D2b: {
          calculation: a_t[:race].eq(3).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as African American (race)',
        },
        D2c: {
          calculation: a_t[:race].eq(2).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Asian (race)',
        },
        D2d: {
          calculation: a_t[:race].eq(1).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as American Indian/Alaska Native (race)',
        },
        D2e: {
          calculation: a_t[:race].eq(4).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Native Hawaiian/Pacific Islander',
        },
        D2f: {
          calculation: a_t[:race].eq(7).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Middle Eastern or North African',
        },
        D2g: {
          calculation: a_t[:ethnicity].eq(1).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Hispanic/Latina/e/o',
        },
        D2h: {
          calculation: a_t[:race].eq(10).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who identified as Other/Multi-racial (race)',
        },
        D2i: {
          calculation: a_t[:language].eq('English').and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served whose primary language was English (language)',
        },
        D2j: {
          calculation: a_t[:language].eq('Spanish').and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served whose primary language was Spanish (language)',
        },
        D2k: {
          calculation: a_t[:language].not_eq(nil).and(a_t[:language].not_eq('English').and(a_t[:language].not_eq('Spanish'))).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served whose primary language was Other (language)',
        },
        D3a: {
          calculation: a_t[:mental_health_disorder].eq(true).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who reported having a Mental Health Disorder',
        },
        D3b: {
          calculation: a_t[:substance_use_disorder].eq(true).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who reported having a Substance Use Disorder',
        },
        D3c: {
          calculation: a_t[:physical_disability].eq(true).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who reported having a Medical/Physical Disability (disability)',
        },
        D3d: {
          calculation: a_t[:developmental_disability].eq(true).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who reported having a Developmental Disability (disability)',
        },
        D4a: {
          calculation: a_t[:pregnant].eq(1).and(a_t[:due_date].gt(filter.start)).or(Arel.sql(custodial_parent_query)).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who were Pregnant or Custodial Parenting',
        },
        D4b: {
          calculation: lgbtq_query.and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who were LGBTQ+',
        },
        D4c: {
          calculation: a_t[:education_status_date].lteq(filter.end).and(a_t[:current_school_attendance].eq(0)).and(a_t[:most_recent_education_status].in([0, 1])).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who had Completed high school or GED/HiSET',
        },
        D4d: {
          calculation: a_t[:education_status_date].lteq(filter.end).and(a_t[:current_school_attendance].in([1, 2])).and(a_t[:current_educational_status].in([1, 2])).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who were enrolled (full or part time) in a 2 or 4 year college',
        },
        D4e: {
          calculation: a_t[:education_status_date].lteq(filter.end).and(a_t[:current_school_attendance].in([1, 2])).and(a_t[:current_educational_status].eq(4)).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who were enrolled and pursuing other post-secondary credential (i.e. votech or certificate program)',
        },
        D4f: {
          calculation: a_t[:health_insurance].eq(true).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who had Health insurance at intake',
        },
        D4g: {
          calculation: a_t[:employed].eq(true).and(a_t[:head_of_household].eq(true)),
          label: 'Number of YYA served who are working a full or part time time job (Employment Status)',
        },
        F2a: {
          calculation: g_population,
          label: 'The number of  YYA who transition into stabilized housing',
        },
        F2b: {
          calculation: g_population.and(a_t[:days_to_return].lteq(730)),
          label: 'Returned to homeless (within 2 years of being housed)',
        },
        G1a: {
          calculation: g_population.and(a_t[:age].lt(18)),
          label: 'Number of YYA served who were Under 18',
        },
        G1b: {
          calculation: g_population.and(a_t[:gender].eq(1)),
          label: 'Number of YYA served who identified as Man',
        },
        G1c: {
          calculation: g_population.and(a_t[:gender].eq(0)),
          label: 'Number of YYA served who identified as Woman',
        },
        G1d: {
          calculation: g_population.and(a_t[:gender].eq(5)),
          label: 'Number of YYA served who identified as Transgender',
        },
        G1e: {
          calculation: g_population.and(a_t[:gender].eq(4)),
          label: 'Number of YYA served who identified as Non-Binary',
        },
        G1f: {
          calculation: g_population.and(a_t[:gender].in([8, 9])),
          label: 'Number of YYA served who are questioning gender/Client doesn\'t know/Client prefers not to answer.',
        },
        G1g: {
          calculation: g_population.and(a_t[:gender].eq(99)),
          label: 'Number of YYA served with no Gender Data collected',
        },
        G2a: {
          calculation: g_population.and(a_t[:race].eq(5)),
          label: 'Number of YYA served who identified as White (race)',
        },
        G2b: {
          calculation: g_population.and(a_t[:race].eq(3)),
          label: 'Number of YYA served who identified as African American (race)',
        },
        G2c: {
          calculation: g_population.and(a_t[:race].eq(2)),
          label: 'Number of YYA served who identified as Asian (race)',
        },
        G2d: {
          calculation: g_population.and(a_t[:race].eq(1)),
          label: 'Number of YYA served who identified as American Indian/Alaska Native (race)',
        },
        G2e: {
          calculation: g_population.and(a_t[:race].eq(4)),
          label: 'Number of YYA served who identified as Native Hawaiian/Pacific Islander',
        },
        G2f: {
          calculation: g_population.and(a_t[:race].eq(7)),
          label: 'Number of YYA served who identified as Hispanic/Latina/e/o',
        },
        G2g: {
          calculation: g_population.and(a_t[:race].eq(6)),
          label: 'Number of YYA served who identified as Other/ Multi-racial',
        },
        G2h: {
          calculation: g_population.and(a_t[:race].eq(10)),
          label: 'Number of YYA served who identified as Other/ Multi-racial',
        },
        G3a: {
          calculation: g_population.and(lgbtq_query),
          label: 'Number of YYA served who were LGBTQ+',
        },
        TotalYYAServedHomeless: {
          calculation: a_t[:currently_homeless].eq(true),
          label: 'Number of unduplicated YYA served (update each quarter)',
        },
        TotalYYAServedPrevention: {
          calculation: a_t[:at_risk_of_homelessness].eq(true),
          label: 'Number of unduplicated YYA served (update each quarter)',
        },
      }
    end

    private def calculators
      {
        A1a: cell_definitions[:A1a][:calculation],
        A1b: cell_definitions[:A1b][:calculation],

        A2a: cell_definitions[:A2a][:calculation],
        A2b: cell_definitions[:A2b][:calculation],

        A3a: cell_definitions[:A3a][:calculation],
        A3b: cell_definitions[:A3b][:calculation],

        A4a: cell_definitions[:A4a][:calculation],
        A4b: cell_definitions[:A4b][:calculation],
        TotalYYAServedHomeless: cell_definitions[:TotalYYAServedHomeless][:calculation],
        TotalYYAServedPrevention: cell_definitions[:TotalYYAServedPrevention][:calculation],

        D1a: cell_definitions[:D1a][:calculation],
        D1b: cell_definitions[:D1b][:calculation],
        D1c: cell_definitions[:D1c][:calculation],
        D1d: cell_definitions[:D1d][:calculation],
        D1e: cell_definitions[:D1e][:calculation],
        D1f: cell_definitions[:D1f][:calculation],
        D1g: cell_definitions[:D1g][:calculation],

        D2a: cell_definitions[:D2a][:calculation],
        D2b: cell_definitions[:D2b][:calculation],
        D2c: cell_definitions[:D2c][:calculation],
        D2d: cell_definitions[:D2d][:calculation],
        D2e: cell_definitions[:D2e][:calculation],
        D2f: cell_definitions[:D2f][:calculation],
        D2g: cell_definitions[:D2g][:calculation],
        D2h: cell_definitions[:D2h][:calculation],
        D2i: cell_definitions[:D2i][:calculation],
        D2j: cell_definitions[:D2j][:calculation],
        D2k: cell_definitions[:D2k][:calculation],

        D3a: cell_definitions[:D3a][:calculation],
        D3b: cell_definitions[:D3b][:calculation],
        D3c: cell_definitions[:D3c][:calculation],
        D3d: cell_definitions[:D3d][:calculation],

        D4a: cell_definitions[:D4a][:calculation],
        D4b: cell_definitions[:D4b][:calculation],
        D4c: cell_definitions[:D4c][:calculation],
        D4d: cell_definitions[:D4d][:calculation],
        D4e: cell_definitions[:D4e][:calculation],
        D4f: cell_definitions[:D4f][:calculation],
        D4g: cell_definitions[:D4g][:calculation],

        F2a: cell_definitions[:F2a][:calculation],
        F2b: cell_definitions[:F2b][:calculation],

        G1a: cell_definitions[:G1a][:calculation],
        G1b: cell_definitions[:G1b][:calculation],
        G1c: cell_definitions[:G1c][:calculation],
        G1d: cell_definitions[:G1d][:calculation],
        G1e: cell_definitions[:G1e][:calculation],
        G1f: cell_definitions[:G1f][:calculation],
        G1g: cell_definitions[:G1g][:calculation],

        G2a: cell_definitions[:G2a][:calculation],
        G2b: cell_definitions[:G2b][:calculation],
        G2c: cell_definitions[:G2c][:calculation],
        G2d: cell_definitions[:G2d][:calculation],
        G2e: cell_definitions[:G2e][:calculation],
        G2f: cell_definitions[:G2f][:calculation],
        G2g: cell_definitions[:G2g][:calculation],
        G2h: cell_definitions[:G2h][:calculation],

        G3a: cell_definitions[:G3a][:calculation],

      }.freeze
    end

    def label(key)
      case key
      when :TotalYYAServedHomeless
        'Total YYA Served: Homeless/Rehousing'
      when :TotalYYAServedPrevention
        'Total YYA Served: Prevention'
      else
        key.to_s.underscore.titleize
      end
    end

    private def lgbtq_query
      # Report defines LGBTQ as:
      #   SexualOrientation = gay(2), lesbian(3), bisexual(4), questioning(5), OR
      #   Gender = transgender(5)
      a_t[:sexual_orientation].in([2, 3, 4, 5]).or(a_t[:gender].eq(5))
    end

    # More than one person in the household,
    # and one household member must be less than 18
    private def custodial_parent_query
      query = ' jsonb_array_length(household_ages) > 1 '
      query += " AND ma_yya_report_clients.id in ( SELECT ages.id FROM ( SELECT id, translate(household_ages::text, '[]', '{}')::integer [] AS h_ages FROM ma_yya_report_clients) ages WHERE 18 > ANY (h_ages) )"
      query
    end

    private def json_contains(field, contents)
      "(#{contents.map { |val| "#{field} @> '#{val}'" }.join(' OR ')})"
    end

    # Check whether an array of strings contains a given text value (case insensitive)
    private def json_contains_text(field, text)
      "lower(#{field}::text)::jsonb ? '#{text.downcase}'"
    end

    private def report_results
      calculators.each do |cell_name, query|
        cell = report_cells.create(name: cell_name)
        case cell_name
        when 'F2d' # a list of zipcodes
          cell.update(structured_data: universe.members.pluck(a_t[:zip_codes]).flatten)
        else
          next if query.nil? # Create a cell for a Non-HMIS query, but leave it blank

          clients = universe.members.where(query)
          cell.add_members(clients)
          cell.update!(summary: clients.count)
        end
      end
    end

    def labels
      calculators.keys
    end

    def section_label(label)
      @section_label ||= {
        'A' => 'A. Core Services',
        # 'C' => 'C. College Student Services (all regions)',
        'D' => 'D. Demographics',
        'E' => 'E. Youth Action Board/Youth Engagement Activity',
        'F' => 'F. Outcomes',
        'G' => 'G. Demographics of Rehousing Outcomes: youth who transitioned into stabilized housing (YTD should be unduplicated and match F2a)',
      }
      @section_label[label]
    end

    def subsection_label(label)
      @subsection_label ||= {
        'A1' => { text: '1. Street Outreach/Colaboration' },
        'A2' => { text: '2. Referrals Received' },
        'A3' => { text: '3. Assessment/Case Management/Case Coordination - Prevention' },
        'A4' => { text: '4. Assessment/Case Management/Case Coordination - Rehousing' },
        'A5' => { text: '5. Direct Financial Assistance (Flex Funds)' },
        # 'C1' => { text: '1. Transitional Housing & Case Management (enrolled students)' },
        # 'C3' => { text: '2. Number College students' },
        'D1' => { text: '1. Age and Gender' },
        'D2' => { text: '2. Race, Ethnicity, and Language' },
        'D3' => { text: '3. Disability' },
        'D4' => { text: '4. Other' },
        'F1' => { text: '1. Prevention / Diversion/ Problem Solving Outcomes (Follow up)' },
        'F2' => { text: '2. Rehousing Outcomes' },
        'G1' => { text: '1. Age and Gender' },
        'G2' => { text: '2. Race, Ethnicity, and Language' },
        'G3' => { text: '3. Other' },
      }
      @subsection_label[label] || { text: '' }
    end

    def cell_label(label)
      cell_labels[label]
    end

    def row_count(key)
      row_counts[key] || 1
    end

    private def row_counts
      @row_counts ||= cell_labels.keys.
        group_by { |k| k.to_s.first(2) }.
        transform_values(&:count)
    end

    private def cell_labels
      @cell_labels ||= cell_definitions.transform_values { |definition| definition[:label] }
      #   A1a: cell_definitions[:A1a][:label],
      #   A1b: cell_definitions[:A1b][:label],
      #   A2a: cell_definitions[:A2a][:label],
      #   A2b: cell_definitions[:A2b][:label],
      #   A3a: cell_definitions[:A3a][:label],
      #   A3b: cell_definitions[:A3b][:label],
      #   # A3c: 'Number of YYA turned away',
      #   A4a: cell_definitions[:A4a][:label],
      #   A4b: cell_definitions[:A4b][:label],
      #   # A4c: 'Number of YYA turned away',
      #   # A5a: 'Total number of YYA who received direct financial assistance/flex funds',
      #   # A5b: 'Number of YYA who received assistance with Move-in costs',
      #   # A5c: 'Number of YYA who received assistance with Rent',
      #   # A5d: 'Number of YYA who received assistance with Rent arrears',
      #   # A5e: 'Number of YYA who received assistance with Utilities',
      #   # A5f: 'Number of YYA who received assistance with Transportation-related costs',
      #   # A5g: 'Number of YYA who received assistance with Education-related costs',
      #   # A5h: 'Number of YYA who received assistance with Legal costs',
      #   # A5i: 'Number of YYA who received assistance with Child care',
      #   # A5j: 'Number of YYA who received assistance with Work-related costs',
      #   # A5k: 'Number of YYA who received assistance with Medical costs',
      #   # A5l: 'Number of YYA who received assistance with Cell phone costs',
      #   # A5m: 'Number of YYA who received assistance with Food/groceries',
      #   # A5n: 'Number of YYA who received assistance with Other costs',
      #   TotalYYAServedHomeless: cell_definitions[:TotalYYAServedHomeless][:label],
      #   TotalYYAServedPrevention: cell_definitions[:TotalYYAServedPrevention][:label],
      #   # C1: 'Number of Pilot Program  students receiving Transitional Housing & Case Management services',
      #   # C3: 'Number of College students not officially enrolled in the campus pilot program that are receiving services',
      #   D1a: cell_definitions[:D1a][:label],
      #   D1b: cell_definitions[:D1b][:label],
      #   D1c: cell_definitions[:D1c][:label],
      #   D1d: cell_definitions[:D1d][:label],
      #   D1e: cell_definitions[:D1e][:label],
      #   D1f: cell_definitions[:D1f][:label],
      #   D1g: cell_definitions[:D1g][:label],
      #   D2a: cell_definitions[:D2a][:label],
      #   D2b: cell_definitions[:D2b][:label],
      #   D2c: cell_definitions[:D2c][:label],
      #   D2d: cell_definitions[:D2d][:label],
      #   D2e: cell_definitions[:D2e][:label],
      #   D2f: cell_definitions[:D2f][:label],
      #   D2g: cell_definitions[:D2g][:label],
      #   D2h: cell_definitions[:D2h][:label],
      #   D2i: cell_definitions[:D2i][:label],
      #   D2j: cell_definitions[:D2j][:label],
      #   D2k: cell_definitions[:D2k][:label],
      #   D3a: cell_definitions[:D3a][:label],
      #   D3b: cell_definitions[:D3b][:label],
      #   D3c: cell_definitions[:D3c][:label],
      #   D3d: cell_definitions[:D3d][:label],
      #   D4a: cell_definitions[:D4a][:label],
      #   D4b: cell_definitions[:D4b][:label],
      #   D4c: cell_definitions[:D4c][:label],
      #   D4d: cell_definitions[:D4d][:label],
      #   D4e: cell_definitions[:D4e][:label],
      #   D4f: cell_definitions[:D4f][:label],
      #   D4g: cell_definitions[:D4g][:label],
      #   # Ea: 'Number of Meetings',
      #   # Eb: 'Number of unduplicated participants',
      #   # F1a: 'Number of YYA contacted for follow up 3 mos. after receiving prevention services',
      #   # F1b: 'Number of YYA who remain housed 3 mos. after receiving prevention services',
      #   F2a: cell_definitions[:F2a][:label],
      #   F2b: cell_definitions[:F2b][:label],
      #   # F2c: 'Number of YYA who are in housing 3 mos. after receiving rehousing services',
      #   # F2d: 'Zip codes of stabilized housing (please list)',
      #   G1a: cell_definitions[:G1a][:label],
      #   G1b: cell_definitions[:G1b][:label],
      #   G1c: cell_definitions[:G1c][:label],
      #   G1d: cell_definitions[:G1d][:label],
      #   G1e: cell_definitions[:G1e][:label],
      #   G1f: cell_definitions[:G1f][:label],
      #   G1g: cell_definitions[:G1g][:label],
      #   G2a: cell_definitions[:G2a][:label],
      #   G2b: cell_definitions[:G2b][:label],
      #   G2c: cell_definitions[:G2c][:label],
      #   G2d: cell_definitions[:G2d][:label],
      #   G2e: cell_definitions[:G2e][:label],
      #   G2f: cell_definitions[:G2f][:label],
      #   G2g: cell_definitions[:G2g][:label],
      #   G2h: cell_definitions[:G2h][:label],
      #   G3a: cell_definitions[:G3a][:label],
      # }
    end

    def cell(cell_name)
      report_cells.find_by(name: cell_name)
    end

    def answer(cell_name)
      cell(cell_name)&.summary
    end

    def list_answer(cell_name)
      cell(cell_name)&.structured_data&.join(', ')
    end

    def format_value(value, key)
      return HudUtility2026.gender(value) if key == 'gender'
      return format_race(value) if key == 'race'

      case value
      when Array
        value.join(', ')
      when TrueClass, FalseClass
        value ? 'Yes' : 'No'
      else
        value
      end
    end

    private def format_race(value)
      if value.in?(HudUtility2026.race_known_ids)
        field = HudUtility2024.race_id_to_field_name[value]
        return HudUtility2026.race(field)
      elsif value == 10
        return 'Multi-racial'
      elsif value.in?(HudUtility2026.race_nones.keys)
        return HudUtility2026.race_none(value)
      end

      value
    end

    def self.yya_projects(user)
      ::GrdaWarehouse::Hud::Project.options_for_select(user: user)
    end

    def self.available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
      }
    end

    def self.report_options
      [
        :start,
        :end,
        :coc_codes,
        :project_ids,
        :project_group_ids,
        :organization_ids,
        :data_source_ids,
        :age_ranges,
      ].freeze
    end
  end
end
