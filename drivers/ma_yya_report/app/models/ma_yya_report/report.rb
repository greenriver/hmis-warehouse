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

    private def prevention_clause
      a_t[:at_risk_of_homelessness].eq(true)
    end

    private def homeless_clause
      a_t[:currently_homeless].eq(true).
        or(a_t[:homeless_enrollment_started_during_range].eq(true)). # A4a
        or(a_t[:homeless_enrollment_started_prior_to_range].eq(true)) # A4b
    end

    # This is the value for F1a and the universe for G
    private def prevention_remained_housed_clause
      prevention_clause.and(a_t[:entry_date].gt(a_t[:latest_homeless_cls_in_range]))
    end

    # This is the value for F2a and the universe for H
    private def became_housed_clause
      homeless_clause.
        and(a_t[:latest_homeless_entry_date].lt(a_t[:permanent_exit_date]))
    end

    private def nested_cell_definitions
      @nested_cell_definitions ||= {
        'A' => {
          section_label: 'A. Core Services',
          subsections: {
            'A1' => {
              subsection_label: '1. Street Outreach/Colaboration',
              cells: section_a1_cells,
            },
            'A2' => {
              subsection_label: '2. Referrals Received',
              cells: section_a2_cells,
            },
            'A3' => {
              subsection_label: '3. Assessment/Case Management/Case Coordination - Prevention',
              cells: section_a3_cells,
            },
            'A4' => {
              subsection_label: '4. Assessment/Case Management/Case Coordination - Rehousing',
              cells: section_a4_cells,
            },
            'A_Total' => {
              subsection_label: 'Totals',
              cells: section_a_total_cells,
            },
          },
        },
        'D' => {
          section_label: 'D. Prevention Demographics',
          subsections: {
            'D1' => {
              subsection_label: '1. Age and Gender',
              cells: section_d1_e1_cells(section: 'D', clause: prevention_clause),
            },
            'D2' => {
              subsection_label: '2. Race, Ethnicity, and Language',
              cells: section_d2_e2_cells(section: 'D', clause: prevention_clause),
            },
            'D3' => {
              subsection_label: '3. Disability',
              cells: section_d3_e3_cells(section: 'D', clause: prevention_clause),
            },
            'D4' => {
              subsection_label: '4. Other',
              cells: section_d4_e4_cells(section: 'D', clause: prevention_clause),
            },
          },
        },
        'E' => {
          section_label: 'E. Homeless/rehousing Demographics',
          subsections: {
            'E1' => {
              subsection_label: '1. Age and Gender',
              cells: section_d1_e1_cells(section: 'E', clause: homeless_clause),
            },
            'E2' => {
              subsection_label: '2. Race, Ethnicity, and Language',
              cells: section_d2_e2_cells(section: 'E', clause: homeless_clause),
            },
            'E3' => {
              subsection_label: '3. Disability',
              cells: section_d3_e3_cells(section: 'E', clause: homeless_clause),
            },
            'E4' => {
              subsection_label: '4. Other',
              cells: section_d4_e4_cells(section: 'E', clause: homeless_clause),
            },
          },
        },
        'F' => {
          section_label: 'F. Outcomes',
          subsections: {
            'F1' => {
              subsection_label: '1. Prevention / Diversion/ Problem Solving Outcomes (Follow up)',
              cells: section_f1_cells,
            },
            'F2' => {
              subsection_label: '2. Rehousing Outcomes',
              cells: section_f2_cells,
            },
          },
        },
        'G' => {
          section_label: 'G. Demographics of Rehousing Outcomes: youth served in prevention who remained housed during the reporting period (YTD should be unduplicated and match F-1a.))',
          subsections: {
            'G1' => {
              subsection_label: '1. Age and Gender',
              cells: section_g1_h1_cells(section: 'G', clause: prevention_remained_housed_clause),
            },
            'G2' => {
              subsection_label: '2. Race, Ethnicity, and Language',
              cells: section_g2_h2_cells(section: 'G', clause: prevention_remained_housed_clause),
            },
            'G3' => {
              subsection_label: '3. Other',
              cells: section_g3_h3_cells(section: 'G', clause: prevention_remained_housed_clause),
            },
          },
        },
        'H' => {
          section_label: 'H. Demographics of Rehousing Outcomes: youth who transitioned into stabilized housing during the reporting period (YTD should be unduplicated and match F-2a.)))',
          subsections: {
            'H1' => {
              subsection_label: '1. Age and Gender',
              cells: section_g1_h1_cells(section: 'H', clause: became_housed_clause),
            },
            'H2' => {
              subsection_label: '2. Race, Ethnicity, and Language',
              cells: section_g2_h2_cells(section: 'H', clause: became_housed_clause),
            },
            'H3' => {
              subsection_label: '3. Other',
              cells: section_g3_h3_cells(section: 'H', clause: became_housed_clause),
            },
          },
        },
      }.freeze
    end

    private def section_a1_cells
      {
        A1a: {
          calculation: a_t[:enrolled_in_street_outreach].eq(true).
            and(a_t[:currently_homeless].eq(true)),
          label: 'Unduplicated number of outreach contacts with YYA experiencing homelessness',
        },
        A1b: {
          calculation: a_t[:referral_source].eq(7). # referred from Outreach Project
            and(a_t[:at_risk_of_homelessness].eq(true)),
          label: 'Unduplicated number of outreach contacts with YYA considered "at-risk" of homelessness',
        },
      }
    end

    private def section_a2_cells
      {
        A2a: {
          calculation: a_t[:initial_contact].eq(true).
            and(a_t[:currently_homeless].eq(true)).
            # Don't double count outreach contacts
            and(a_t[:enrolled_in_street_outreach].eq(false)).
            and(a_t[:referral_source].not_eq(7)),
          label: 'Unduplicated number of initial contacts with YYA experiencing homelessness',
        },
        A2b: {
          calculation: a_t[:initial_contact].eq(true).
            and(a_t[:at_risk_of_homelessness].eq(true)).
            # Don't double count outreach contacts
            and(a_t[:enrolled_in_street_outreach].eq(false)).
            and(a_t[:referral_source].not_eq(7)),
          label: 'Unduplicated number of initial contacts with YYA considered "at-risk" of homelessness',
        },
      }
    end

    private def section_a3_cells
      {
        A3a: {
          calculation: a_t[:entry_date].gteq(filter.start).
            and(a_t[:at_risk_of_homelessness].eq(true)),
          label: 'Number of YYA completing new intake: YYA considered "at-risk" of homelessness',
        },
        A3b: {
          calculation: a_t[:entry_date].lt(filter.start).
            and(a_t[:latest_non_homeless_cls_in_range].gt(filter.start)),
          label: 'Number of YYA continuing in case management',
        },
      }
    end

    private def section_a4_cells
      {
        A4a: {
          calculation: a_t[:entry_date].gteq(filter.start).
            and(a_t[:currently_homeless].eq(true)),
          label: 'Number of YYA completing new intake: YYA experiencing homelessness',
        },
        A4b: {
          calculation: a_t[:entry_date].lt(filter.start).
            and(a_t[:latest_homeless_cls_in_range].gt(filter.start)).
            and(a_t[:currently_homeless].eq(true)),
          label: 'Number of YYA continuing in case management',
        },
      }
    end

    private def section_a_total_cells
      {
        TotalYYAServedPrevention: {
          calculation: prevention_clause,
          label: 'Number of unduplicated YYA served (update each quarter)',
        },
        TotalYYAServedHomeless: {
          # Currently homeless based on CLS or ongoing homeless enrollment
          calculation: homeless_clause,
          label: 'Number of unduplicated YYA served (update each quarter)',
        },
      }
    end

    private def section_d1_e1_cells(section:, clause:)
      {
        "#{section}1a": {
          calculation: a_t[:age].lt(18).and(clause),
          label: 'Number of YYA served who were Under 18',
        },
        "#{section}1b": {
          calculation: a_t[:gender].eq(1).and(clause),
          label: 'Number of YYA served who identified as Man',
        },
        "#{section}1c": {
          calculation: a_t[:gender].eq(0).and(clause),
          label: 'Number of YYA served who identified as Woman',
        },
        "#{section}1d": {
          calculation: a_t[:gender].eq(5).and(clause),
          label: 'Number of YYA served who identified as Transgender',
        },
        "#{section}1e": {
          calculation: a_t[:gender].eq(4).and(clause),
          label: 'Number of YYA served who identified as Non-Binary',
        },
        "#{section}1f": {
          calculation: a_t[:gender].in([8, 9]).and(clause),
          label: 'Number of YYA served who  are questioning gender/Client doesn\'t know/Client prefers not to answer.',
        },
        "#{section}1g": {
          calculation: a_t[:gender].eq(99).and(clause),
          label: 'Number of YYA served with no Gender Data collected',
        },
      }
    end

    private def section_d2_e2_cells(section:, clause:)
      {
        "#{section}2a": {
          calculation: a_t[:race].eq(5).and(clause),
          label: 'Number of YYA served who identified as White (race)',
        },
        "#{section}2b": {
          calculation: a_t[:race].eq(3).and(clause),
          label: 'Number of YYA served who identified as African American (race)',
        },
        "#{section}2c": {
          calculation: a_t[:race].eq(2).and(clause),
          label: 'Number of YYA served who identified as Asian (race)',
        },
        "#{section}2d": {
          calculation: a_t[:race].eq(1).and(clause),
          label: 'Number of YYA served who identified as American Indian/Alaska Native (race)',
        },
        "#{section}2e": {
          calculation: a_t[:race].eq(4).and(clause),
          label: 'Number of YYA served who identified as Native Hawaiian/Pacific Islander',
        },
        "#{section}2f": {
          calculation: a_t[:race].eq(7).and(clause),
          label: 'Number of YYA served who identified as Middle Eastern or North African',
        },
        "#{section}2g": {
          calculation: a_t[:ethnicity].eq(1).and(clause),
          label: 'Number of YYA served who identified as Hispanic/Latina/e/o',
        },
        "#{section}2h": {
          calculation: a_t[:race].eq(10).and(clause),
          label: 'Number of YYA served who identified as Other/Multi-racial (race)',
        },
        "#{section}2i": {
          calculation: a_t[:language].eq('English').and(clause),
          label: 'Number of YYA served whose primary language was English (language)',
        },
        "#{section}2j": {
          calculation: a_t[:language].eq('Spanish').and(clause),
          label: 'Number of YYA served whose primary language was Spanish (language)',
        },
        "#{section}2k": {
          calculation: a_t[:language].not_eq(nil).and(a_t[:language].not_eq('English').and(a_t[:language].not_eq('Spanish'))).and(clause),
          label: 'Number of YYA served whose primary language was Other (language)',
        },
      }
    end

    private def section_d3_e3_cells(section:, clause:)
      {
        "#{section}3a": {
          calculation: a_t[:mental_health_disorder].eq(true).and(clause),
          label: 'Number of YYA served who reported having a Mental Health Disorder',
        },
        "#{section}3b": {
          calculation: a_t[:substance_use_disorder].eq(true).and(clause),
          label: 'Number of YYA served who reported having a Substance Use Disorder',
        },
        "#{section}3c": {
          calculation: a_t[:physical_disability].eq(true).and(clause),
          label: 'Number of YYA served who reported having a Medical/Physical Disability (disability)',
        },
        "#{section}3d": {
          calculation: a_t[:developmental_disability].eq(true).and(clause),
          label: 'Number of YYA served who reported having a Developmental Disability (disability)',
        },
      }
    end

    private def section_d4_e4_cells(section:, clause:)
      {
        "#{section}4a": {
          calculation: a_t[:pregnant].eq(1).
            and(a_t[:due_date].gt(filter.start)).
            or(Arel.sql(custodial_parent_query)).
            and(clause),
          label: 'Number of YYA served who were Pregnant or Custodial Parenting',
        },
        "#{section}4b": {
          calculation: lgbtq_query.
            and(clause),
          label: 'Number of YYA served who were LGBTQ+',
        },
        "#{section}4c": {
          calculation: a_t[:education_status_date].lteq(filter.end).
            and(a_t[:current_school_attendance].eq(0)).
            and(a_t[:most_recent_education_status].in([0, 1])).
            and(clause),
          label: 'Number of YYA served who had Completed high school or GED/HiSET',
        },
        "#{section}4d": {
          calculation: a_t[:education_status_date].lteq(filter.end).
            and(a_t[:current_school_attendance].in([1, 2])).
            and(a_t[:current_educational_status].in([1, 2])).
            and(clause),
          label: 'Number of YYA served who were enrolled (full or part time) in a 2 or 4 year college',
        },
        "#{section}4e": {
          calculation: a_t[:education_status_date].lteq(filter.end).
            and(a_t[:current_school_attendance].in([1, 2])).
            and(a_t[:current_educational_status].eq(4)).
            and(clause),
          label: 'Number of YYA served who were enrolled and pursuing other post-secondary credential (i.e. votech or certificate program)',
        },
        "#{section}4f": {
          calculation: a_t[:health_insurance].eq(true).
            and(clause),
          label: 'Number of YYA served who had Health insurance at intake',
        },
        "#{section}4g": {
          calculation: a_t[:employed].eq(true).
            and(clause),
          label: 'Number of YYA served who are working a full or part time time job (Employment Status)',
        },
        "#{section}4h": {
          calculation: a_t[:former_foster_ward].eq(true).
            and(clause),
          label: 'Number of YYA served who were Formerly a Ward of Child Welfare/Foster Care Agency',
        },
        "#{section}4i": {
          calculation: a_t[:former_juvenile_justice_ward].eq(true).
            and(clause),
          label: 'Number of YYA served who are currently in voluntary services with DCF',
        },
        "#{section}4j": {
          calculation: a_t[:voluntary_dcf_service].eq(true).
            and(clause),
          label: 'Number of YYA served who were Formerly a Ward of Juvenile Justice System',
        },
        "#{section}4k": {
          calculation: a_t[:voluntary_dys_yes_service].eq(true).
            and(clause),
          label: 'Number of YYA served who are currently in voluntary services with DYS/YES program',
        },
        "#{section}4l": {
          calculation: a_t[:exchange_for_sex].eq(true).
            and(clause),
          label: 'Number of YYA who have ever received anything in exchange for sex (ESN/Commercial Sexual Exploitation/Sex Trafficking)',
        },
      }
    end

    private def section_f1_cells
      {
        # in prevention, and haven't been homeless since
        F1a: {
          calculation: prevention_remained_housed_clause,
          label: 'Number of YYA served in prevention who remained housed during reporting period',
        },
        F1b: {
          calculation: a_t[:first_prevention_date].lteq(filter.start),
          label: 'Number of YYA who received prevention services in the last 2 years',
        },
        F1c: {
          calculation: a_t[:first_prevention_date].lteq(filter.start).
            and(a_t[:latest_homeless_entry_date].eq(nil).
              or(a_t[:latest_homeless_entry_date].lt(a_t[:first_prevention_date]))).
            and(a_t[:latest_homeless_cls].eq(nil).
              or(a_t[:latest_homeless_cls].lt(a_t[:first_prevention_date]))),
          label: 'Number of YYA who remain housed 2 years after receiving prevention services',
        },
        F1d: {
          calculation: a_t[:first_prevention_date_in_last_year].lteq(filter.start).
            and(a_t[:latest_homeless_entry_date].eq(nil).
              or(a_t[:latest_homeless_entry_date].lt(a_t[:first_prevention_date_in_last_year]))).
            and(a_t[:latest_homeless_cls].eq(nil).
              or(a_t[:latest_homeless_cls].lt(a_t[:first_prevention_date_in_last_year]))),
          label: 'Number of YYA who received prevention services in the last year',
        },
        F1e: {
          calculation: a_t[:first_prevention_date_in_last_year].lteq(filter.start).
            and(a_t[:latest_homeless_entry_date].eq(nil).
              or(a_t[:latest_homeless_entry_date].lt(a_t[:first_prevention_date_in_last_year]))).
            and(a_t[:latest_homeless_cls].eq(nil).
              or(a_t[:latest_homeless_cls].lt(a_t[:first_prevention_date_in_last_year]))),
          label: 'Number of YYA who remain housed 1 year after receiving prevention services',
        },
      }
    end

    private def section_f2_cells
      {
        F2a: {
          calculation: became_housed_clause,
          label: 'The number of  YYA who transition into stabilized housing during reporting period',
        },
        F2b: {
          calculation: a_t[:first_homeless_date].lt(a_t[:permanent_exit_date]),
          label: 'Number of YYA served who exited to a permanent housing situation in the past 2 years',
        },
        F2c: {
          calculation: a_t[:first_homeless_date].lt(a_t[:permanent_exit_date]).
            and(a_t[:latest_homeless_entry_date].gt(a_t[:permanent_exit_date])),
          label: 'Number of YYA served who returned to homeless within 2 years of being housed',
        },
        F2d: {
          calculation: a_t[:first_homeless_date_in_last_year].lt(a_t[:permanent_exit_date]),
          label: 'Number of YYA served who exited to a permanent housing situation in the past year',
        },
        F2e: {
          calculation: a_t[:first_homeless_date_in_last_year].lt(a_t[:permanent_exit_date]).
            and(a_t[:latest_homeless_entry_date].gt(a_t[:permanent_exit_date])),
          label: 'Number of YYA returned to homeless within 1 year of being housed',
        },
      }
    end

    private def section_g1_h1_cells(section:, clause:)
      {
        "#{section}1a": {
          calculation: clause.and(a_t[:age].lt(18)),
          label: 'Number of YYA served who were Under 18',
        },
        "#{section}1b": {
          calculation: clause.and(a_t[:gender].eq(1)),
          label: 'Number of YYA served who identified as Man',
        },
        "#{section}1c": {
          calculation: clause.and(a_t[:gender].eq(0)),
          label: 'Number of YYA served who identified as Woman',
        },
        "#{section}1d": {
          calculation: clause.and(a_t[:gender].eq(5)),
          label: 'Number of YYA served who identified as Transgender',
        },
        "#{section}1e": {
          calculation: clause.and(a_t[:gender].eq(4)),
          label: 'Number of YYA served who identified as Non-Binary',
        },
        "#{section}1f": {
          calculation: clause.and(a_t[:gender].in([6, 8, 9])),
          label: 'Number of YYA served who are questioning gender/Client doesn\'t know/Client prefers not to answer.',
        },
        "#{section}1g": {
          calculation: clause.and(a_t[:gender].eq(99)),
          label: 'Number of YYA served with no Gender Data collected',
        },
      }
    end

    private def section_g2_h2_cells(section:, clause:)
      {
        "#{section}2a": {
          calculation: clause.and(a_t[:race].eq(5)),
          label: 'Number of YYA served who identified as White (race)',
        },
        "#{section}2b": {
          calculation: clause.and(a_t[:race].eq(3)),
          label: 'Number of YYA served who identified as African American (race)',
        },
        "#{section}2c": {
          calculation: clause.and(a_t[:race].eq(2)),
          label: 'Number of YYA served who identified as Asian (race)',
        },
        "#{section}2d": {
          calculation: clause.and(a_t[:race].eq(1)),
          label: 'Number of YYA served who identified as American Indian/Alaska Native (race)',
        },
        "#{section}2e": {
          calculation: clause.and(a_t[:race].eq(4)),
          label: 'Number of YYA served who identified as Native Hawaiian/Pacific Islander',
        },
        "#{section}2f": {
          calculation: clause.and(a_t[:race].eq(7)),
          label: 'Number of YYA served who identified as Middle Eastern or North African',
        },
        "#{section}2g": {
          calculation: clause.and(a_t[:race].eq(6)),
          label: 'Number of YYA served who identified as Hispanic/Latina/e/o',
        },
        "#{section}2h": {
          calculation: clause.and(a_t[:race].eq(6)),
          label: 'Number of YYA served who identified as Other/ Multi-racial',
        },
        "#{section}2i": {
          calculation: clause.and(a_t[:race].in([8, 9, 99])),
          label: 'Number of YYA served who answered don\'t know/prefer not to answer/data not collected (race)',
        },
      }
    end

    private def section_g3_h3_cells(section:, clause:)
      {
        "#{section}3a": {
          calculation: clause.and(lgbtq_query),
          label: 'Number of YYA served who were LGBTQ+',
        },
      }
    end

    private def calculators
      @calculators ||= nested_cell_definitions.flat_map do |_, section|
        section[:subsections].flat_map do |_, subsection|
          subsection[:cells].map { |cell_key, cell_data| [cell_key, cell_data[:calculation]] }
        end
      end.to_h
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
      #   Gender = transgender(5), questioning(6)
      a_t[:sexual_orientation].in([2, 3, 4, 5]).or(a_t[:gender].in([5, 6]))
    end

    # More than one person in the household,
    # and one household member must be less than 18
    private def custodial_parent_query
      query = ' jsonb_array_length(household_ages) > 1 '
      query += " AND ma_yya_report_clients.id in ( SELECT ages.id FROM ( SELECT id, translate(household_ages::text, '[]', '{}')::integer [] AS h_ages FROM ma_yya_report_clients) ages WHERE 18 > ANY (h_ages) )"
      query
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
      section_labels[label]
    end

    def subsection_label(label)
      subsection_labels[label] || { text: '' }
    end

    private def section_labels
      @section_labels ||= nested_cell_definitions.transform_values { |section| section[:section_label] }
    end

    private def subsection_labels
      @subsection_labels ||= nested_cell_definitions.flat_map do |_, section|
        section[:subsections].map { |subsection_key, subsection| [subsection_key, { text: subsection[:subsection_label] }] }
      end.to_h
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
      @cell_labels ||= nested_cell_definitions.flat_map do |_, section|
        section[:subsections].flat_map do |_, subsection|
          subsection[:cells].map { |cell_key, cell_data| [cell_key, cell_data[:label]] }
        end
      end.to_h
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
