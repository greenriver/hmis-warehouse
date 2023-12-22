###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    private def calculators # rubocop:disable Metrics/AbcSize
      report_start_date = filter.start
      report_end_date = filter.end

      g_population = a_t[:reported_previous_period].eq(false).
        and(a_t[:head_of_household].eq(true)).
        and(
          a_t[:at_risk_of_homelessness].eq(true).
            and(Arel.sql(
                  json_contains(:subsequent_current_living_situations,
                                [215, 206, 207, 225, 204, 205, 329, 314, 332, 336, 335, 435, 410, 421, 411]),
                )),
        ).
        or(a_t[:currently_homeless].eq(true).and(a_t[:rehoused_on].between(report_start_date..report_end_date)).
          and(a_t[:subsequent_current_living_situations].not_eq([])))

      {
        A1a: a_t[:referral_source].eq(7).and(a_t[:currently_homeless].eq(true)),
        A1b: a_t[:referral_source].eq(7).and(a_t[:at_risk_of_homelessness].eq(true)),

        A2a: a_t[:initial_contact].eq(true).and(a_t[:currently_homeless].eq(true)),
        A2b: a_t[:initial_contact].eq(true).and(a_t[:at_risk_of_homelessness].eq(true)),

        A3a: a_t[:entry_date].gteq(report_start_date).and(a_t[:at_risk_of_homelessness].eq(true)),
        A3b: a_t[:entry_date].lt(report_start_date).and(a_t[:at_risk_of_homelessness].eq(true)),
        # A3c: nil, # Non-HMIS queries should be nil

        A4a: a_t[:entry_date].gteq(report_start_date).and(a_t[:currently_homeless].eq(true)),
        A4b: a_t[:entry_date].lt(report_start_date).and(a_t[:currently_homeless].eq(true)),
        # A4c: nil,

        A5a: a_t[:direct_assistance].eq(true),
        A5b: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Move-in'),
              )),
        A5c: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Rent'),
              )),
        A5d: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Rent arrears'), # Change casing? Collected as 'Rent Arrears'
              )),
        A5e: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Utilities'),
              )),
        A5f: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Transportation'),
              )),
        A5g: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Education'),
              )),
        A5h: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Legal'),
              )),
        A5i: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Child care'),
              )),
        A5j: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Work'),
              )),
        A5k: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Medical'),
              )),
        A5l: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Cell phone'),
              )),
        A5m: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Food/Groceries'),
              )),
        A5n: a_t[:direct_assistance].eq(true).
          and(Arel.sql(
                json_contains_text(:flex_funds, 'Other'),
              )),

        TotalYYAServed: a_t[:currently_homeless].eq(true).or(a_t[:at_risk_of_homelessness].eq(true)),

        # No longer included in FY2024 spec, leaving until we confirm it is no longer necessary
        # C1: nil,
        # C3: nil,
        # TotalCollegeStudentsServed: a_t[:education_status_date].lteq(report_end_date).
        #   and(a_t[:current_school_attendance].in([1, 2])).and(a_t[:current_educational_status].in([1, 2, 3, 4])),

        D1a: a_t[:age].lt(18).and(a_t[:head_of_household].eq(true)),
        D1b: a_t[:gender].eq(1).and(a_t[:head_of_household].eq(true)),
        D1c: a_t[:gender].eq(0).and(a_t[:head_of_household].eq(true)),
        D1d: a_t[:gender].eq(5).and(a_t[:head_of_household].eq(true)),
        D1e: a_t[:gender].eq(4).and(a_t[:head_of_household].eq(true)),
        D1f: a_t[:gender].in([8, 9]).and(a_t[:head_of_household].eq(true)),
        D1g: a_t[:gender].eq(99).and(a_t[:head_of_household].eq(true)),

        D2a: a_t[:race].eq(5).and(a_t[:head_of_household].eq(true)),
        D2b: a_t[:race].eq(3).and(a_t[:head_of_household].eq(true)),
        D2c: a_t[:race].eq(2).and(a_t[:head_of_household].eq(true)),
        D2d: a_t[:race].eq(1).and(a_t[:head_of_household].eq(true)),
        D2e: a_t[:race].eq(4).and(a_t[:head_of_household].eq(true)),
        D2f: a_t[:race].eq(7).and(a_t[:head_of_household].eq(true)),
        D2g: a_t[:race].eq(6).and(a_t[:head_of_household].eq(true)),
        D2h: a_t[:race].eq(10).and(a_t[:head_of_household].eq(true)), # multi-racial
        D2i: a_t[:language].eq('English').and(a_t[:head_of_household].eq(true)),
        D2j: a_t[:language].eq('Spanish').and(a_t[:head_of_household].eq(true)),
        D2k: a_t[:language].not_eq(nil).and(a_t[:language].not_eq('English').and(a_t[:language].not_eq('Spanish'))).and(a_t[:head_of_household].eq(true)),

        D3a: a_t[:mental_health_disorder].eq(true).and(a_t[:head_of_household].eq(true)),
        D3b: a_t[:substance_use_disorder].eq(true).and(a_t[:head_of_household].eq(true)),
        D3c: a_t[:physical_disability].eq(true).and(a_t[:head_of_household].eq(true)),
        D3d: a_t[:developmental_disability].eq(true).and(a_t[:head_of_household].eq(true)),

        D4a: a_t[:pregnant].eq(1).and(a_t[:due_date].gt(report_start_date)).
          or(Arel.sql(custodial_parent_query)).and(a_t[:head_of_household].eq(true)),
        D4b: a_t[:sexual_orientation].in([2, 3, 4, 5]).or(a_t[:gender].in([5, 6])).and(a_t[:head_of_household].eq(true)),
        D4c: a_t[:education_status_date].lteq(report_end_date).
          and(a_t[:current_school_attendance].eq(0)).and(a_t[:most_recent_education_status].in([0, 1])).and(a_t[:head_of_household].eq(true)),
        D4d: a_t[:education_status_date].lteq(report_end_date).
          and(a_t[:current_school_attendance].in([1, 2])). # Enrolled
          and(a_t[:current_educational_status].in([1, 2])).and(a_t[:head_of_household].eq(true)), # AA or BA
        D4e: a_t[:education_status_date].lteq(report_end_date).
          and(a_t[:current_school_attendance].in([1, 2])). # Enrolled
          and(a_t[:current_educational_status].eq(4)).and(a_t[:head_of_household].eq(true)), # other post-secondary
        D4f: a_t[:health_insurance].eq(true).and(a_t[:head_of_household].eq(true)),

        # Ea: nil,
        # Eb: nil,

        F1a: a_t[:subsequent_current_living_situations].not_eq([]).and(a_t[:followup_previous_period].eq(false)),
        F1b: a_t[:followup_previous_period].eq(false).
          and(Arel.sql(
                json_contains(:subsequent_current_living_situations,
                              [215, 206, 207, 225, 204, 205, 329, 314, 332, 336, 335, 435, 410, 421, 411]),
              )),

        F2a: a_t[:currently_homeless].eq(true).
          and(a_t[:rehoused_on].between(report_start_date..report_end_date)), # "Report Once" should handled because reporting periods don't overlap
        F2b: a_t[:currently_homeless].eq(true).
          and(a_t[:rehoused_on].between(report_start_date..report_end_date)).
          and(a_t[:subsequent_current_living_situations].not_eq([])),
        F2c: a_t[:currently_homeless].eq(true).
          and(a_t[:rehoused_on].not_eq(nil)).
          and(a_t[:followup_previous_period].eq(false)).
          and(Arel.sql(json_contains(:subsequent_current_living_situations, [435, 410, 421, 411]))),
        F2d: nil, # Handled as a special case in

        G1a: g_population.and(a_t[:age].lt(18)),
        G1b: g_population.and(a_t[:gender].eq(1)),
        G1c: g_population.and(a_t[:gender].eq(0)),
        G1d: g_population.and(a_t[:gender].eq(5)),
        G1e: g_population.and(a_t[:gender].eq(4)),
        G1f: g_population.and(a_t[:gender].in([8, 9])),
        G1g: g_population.and(a_t[:gender].eq(99)),

        G2a: g_population.and(a_t[:race].eq(5)),
        G2b: g_population.and(a_t[:race].eq(3)),
        G2c: g_population.and(a_t[:race].eq(2)),
        G2d: g_population.and(a_t[:race].eq(1)),
        G2e: g_population.and(a_t[:race].eq(4)),
        G2f: g_population.and(a_t[:race].eq(7)),
        G2g: g_population.and(a_t[:race].eq(6)),
        G2h: g_population.and(a_t[:race].eq(10)), # multi-racial

        G3a: g_population.and(a_t[:sexual_orientation].in([2, 3, 4, 5]).or(a_t[:gender].eq(5))),
      }.freeze
    end

    def label(key)
      case key
      when :TotalYYAServed
        'Total YYA Served'
      else
        key.to_s.underscore.titleize
      end
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

    private def json_contains_text(field, text)
      "#{field} ? '#{text}'"
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
      @cell_labels ||= {
        A1a: 'Unduplicated number of outreach contacts with YYA experiencing homelessness',
        A1b: 'Unduplicated number of outreach contacts with YYA considered "at-risk" of homelessness',
        A2a: 'Number of initial contacts: YYA experiencing homelessness',
        A2b: 'Number of initial contacts: YYA considered "at-risk" of homelessness',
        A3a: 'Number of YYA completing new intake: YYA considered "at-risk" of homelessness',
        A3b: 'Number of YYA continuing in case management',
        # A3c: 'Number of YYA turned away',
        A4a: 'Number of YYA completing new intake: YYA experiencing homelessness',
        A4b: 'Number of YYA continuing in case management',
        # A4c: 'Number of YYA turned away',
        A5a: 'Total number of YYA who received direct financial assistance/flex funds',
        A5b: 'Number of YYA who received assistance with Move-in costs',
        A5c: 'Number of YYA who received assistance with Rent',
        A5d: 'Number of YYA who received assistance with Rent arrears',
        A5e: 'Number of YYA who received assistance with Utilities',
        A5f: 'Number of YYA who received assistance with Transportation-related costs',
        A5g: 'Number of YYA who received assistance with Education-related costs',
        A5h: 'Number of YYA who received assistance with Legal costs',
        A5i: 'Number of YYA who received assistance with Child care',
        A5j: 'Number of YYA who received assistance with Work-related costs',
        A5k: 'Number of YYA who received assistance with Medical costs',
        A5l: 'Number of YYA who received assistance with Cell phone costs',
        A5m: 'Number of YYA who received assistance with Food/groceries',
        A5n: 'Number of YYA who received assistance with Other costs',
        # C1: 'Number of Pilot Program  students receiving Transitional Housing & Case Management services',
        # C3: 'Number of College students not officially enrolled in the campus pilot program that are receiving services',
        D1a: 'Number of YYA  served who were Under 18',
        D1b: 'Number of YYA  served who identified as Man',
        D1c: 'Number of YYA  served who identified as Woman',
        D1d: 'Number of YYA  served who identified as Transgender',
        D1e: 'Number of YYA  served who identified as Non-Binary',
        D1f: 'Number of YYA  served who  are questioning gender/Client doesn\'t know/Client prefers not to answer.',
        D1g: 'Number of YYA served with no Gender Data collected',
        D2a: 'Number of YYA  served who identified as White (race)',
        D2b: 'Number of YYA  served who identified as African American (race)',
        D2c: 'Number of YYA  served who identified as Asian (race)',
        D2d: 'Number of YYA  served who identified as American Indian/Alaska Native (race)',
        D2e: 'Number of YYA  served who identified as Native Hawaiian/Pacific Islander',
        D2f: 'Number of YYA  served who identified as Middle Eastern or North African',
        D2g: 'Number of YYA  served who identified as Hispanic/Latina/e/o',
        D2h: 'Number of YYA  served who identified as Other/Multi-racial (race)',
        D2i: 'Number of YYA  served whose primary language was English (language)',
        D2j: 'Number of YYA  served whose primary language was Spanish (language)',
        D2k: 'Number of YYA  served whose primary language was Other (language)',
        D3a: 'Number of YYA served who reported having a Mental Health Disorder',
        D3b: 'Number of YYA served who reported having a Substance Use Disorder',
        D3c: 'Number of YYA served who reported having a Medical/Physical Disability (disability)',
        D3d: 'Number of YYA served who reported having a Developmental Disability (disability)',
        D4a: 'Number of YYA served who were Pregnant or Custodial Parenting',
        D4b: 'Number of YYA served who were LGBTQ+',
        D4c: 'Number of YYA served who had Completed high school or GED/HiSET',
        D4d: 'Number of YYA served who were enrolled (full or part time) in a 2 or 4 year college',
        D4e: 'Number of YYA served who were enrolled and pursuing other post-secondary credential (i.e. votech or certificate program)',
        D4f: 'Number of YYA served who had Health insurance at intake',
        # Ea: 'Number of Meetings',
        # Eb: 'Number of unduplicated participants',
        F1a: 'Number of YYA contacted for follow up 3 mos. after receiving prevention services',
        F1b: 'Number of YYA who remain housed 3 mos. after receiving prevention services',
        F2a: 'The number of  YYA who transition into stabilized housing',
        F2b: 'Number of YYA contacted for follow up 3 mos. after receiving rehousing services',
        F2c: 'Number of YYA who are in housing 3 mos. after receiving rehousing services',
        F2d: 'Zip codes of stabilized housing (please list)',
        G1a: 'Number of YYA  served who were Under 18',
        G1b: 'Number of YYA  served who identified as Man',
        G1c: 'Number of YYA  served who identified as Woman',
        G1d: 'Number of YYA  served who identified as Transgender',
        G1e: 'Number of YYA  served who identified as Non-Binary',
        G1f: 'Number of YYA  served who  are questioning gender/Client doesn\'t know/Client prefers not to answer.',
        G1g: 'Number of YYA served with no Gender Data collected',
        G2a: 'Number of YYA  served who identified as White (race)',
        G2b: 'Number of YYA  served who identified as African American (race)',
        G2c: 'Number of YYA  served who identified as Asian (race)',
        G2d: 'Number of YYA  served who identified as American Indian/Alaska Native (race)',
        G2e: 'Number of YYA served who identified as Native Hawaiian/Pacific Islander',
        G2f: 'Number of YYA  served who identified as Middle Eastern or North African',
        G2g: 'Number of YYA  served who identified as Hispanic/Latina/e/o',
        G2h: ' Number of YYA  served who identified as Other/ Multi-racial',
        G3a: 'Number of YYA served who were LGBTQ+',
      }
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
        :project_ids,
        :age_ranges,
      ].freeze
    end
  end
end
