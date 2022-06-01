###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'

# Useful notes for testing
# reload!;  r = HomelessSummaryReport::Report.last; nr = HomelessSummaryReport::Report.new(user_id: r.user_id); nr.filter = r.filter; nr.run_and_save!
module HomelessSummaryReport
  class Report < SimpleReports::ReportInstance
    extend Memoist
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include SpmBasedReports
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    acts_as_paranoid

    belongs_to :user, optional: true
    has_many :clients
    has_many :results

    after_initialize :filter

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def run_and_save!
      start
      begin
        populate_universe
        populate_results
      rescue Exception => e
        update(failed_at: Time.current)
        raise e
      end
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def describe_filter_as_html
      filter.describe_filter_as_html(
        [
          :start,
          :end,
          :coc_codes,
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
          :funder_ids,
          :hoh_only,
        ],
      )
    end

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::HudFilterBase.new(user_id: user_id, enforce_one_year_range: false)
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false)) if options.present?
        f
      end
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'homeless_summary_report/warehouse_reports/reports'
    end

    def url
      homeless_summary_report_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('System Performance Measures by Sub-Population')
    end

    def description
      _('A summary of SPMs 1, 2, and 7 with sub-population and demographic details')
    end

    def multiple_project_types?
      true
    end

    private def build_control_sections
      # ensure filter has been set
      filter
      [
        build_funding_section,
        build_hoh_control_section,
      ]
    end

    def report_path_array
      [
        :homeless_summary_report,
        :warehouse_reports,
        :reports,
      ]
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    private def populate_universe
      report_clients = {}
      add_clients(report_clients)
    end

    private def populate_results
      results = []
      measures.each do |measure, data|
        headers = data[:headers]
        variants.each do |household_category, spec|
          data[:fields].each do |row|
            field, row_data = row
            results += generate_results_for(
              section: measure,
              household_category: household_category,
              demographic_category: 'all',
              field: field,
              headers: headers,
              data: row_data,
              calculations: row_data[:calculations],
            )
            spec[:variants].each do |demographic_category, _variant|
              next if exclude_variants(measure, demographic_category)

              data[:fields].each do |sub_row|
                next unless sub_row.first == field

                row_data = sub_row.last
                results += generate_results_for(
                  section: measure,
                  household_category: household_category,
                  demographic_category: demographic_category,
                  field: field,
                  headers: headers,
                  data: row_data,
                  calculations: row_data[:calculations],
                )
              end
            end
          end
        end
      end
      HomelessSummaryReport::Result.transaction do
        HomelessSummaryReport::Result.where(report_id: id).update_all(deleted_at: Time.current)
        HomelessSummaryReport::Result.import(results)
      end
    end

    private def generate_results_for(section:, household_category:, demographic_category:, field:, headers:, calculations:, data:)
      [].tap do |results|
        detail_variant_name = "spm_#{household_category}__#{demographic_category}"
        if section == 'Measure 7'
          calculations.each do |calculation|
            if calculation.to_s == 'count'
              value = calculate(detail_variant_name, field, calculation, data)

              results << HomelessSummaryReport::Result.new(
                report_id: id,
                section: section,
                household_category: household_category,
                demographic_category: demographic_category,
                field: field,
                characteristic: headers.first,
                calculation: calculation,
                format: format_string(calculation),
                value: value,
                detail_link_slug: detail_variant_name,
              )
            else
              # For measure 7 we only want the large buckets, we'll add the detail buckets as a json blob
              destination_buckets.each.with_index do |(destination_name, ids), i|
                # skip 'Client Count', that happened above
                next if ids.blank?

                # calculate the overall count of people with this exit destination type
                value = calculate(detail_variant_name, field, calculation, data.merge(destination: ids))
                details = []
                # skip 'Remained housed', it doesn't need details
                unless ids == [0]
                  # calculate the count of people in each destination of the type
                  ids.each do |d_id|
                    count = calculate(detail_variant_name, field, calculation, data.merge(destination: d_id))
                    details << "#{HUD.destination(d_id)}: #{count}" if count&.positive?
                  end
                end

                results << HomelessSummaryReport::Result.new(
                  report_id: id,
                  section: section,
                  household_category: household_category,
                  demographic_category: demographic_category,
                  field: field,
                  characteristic: headers.drop(1)[i],
                  calculation: calculation,
                  format: format_string(calculation),
                  value: value,
                  detail_link_slug: detail_variant_name,
                  destination: destination_name,
                  details: details,
                )
              end
            end
          end
        else
          calculations.each.with_index do |calculation, i|
            value = calculate(detail_variant_name, field, calculation, data)

            results << HomelessSummaryReport::Result.new(
              report_id: id,
              section: section,
              household_category: household_category,
              demographic_category: demographic_category,
              field: field,
              characteristic: headers[i],
              calculation: calculation,
              format: format_string(calculation),
              value: value,
              detail_link_slug: detail_variant_name,
            )
          end
        end
      end
    end

    private def format_string(calculation)
      return '%0.1f' if calculation.in?([:percent, :average])

      '%0d'
    end

    private def results_hash
      @results_hash ||= {}.tap do |r|
        results.find_each do |row|
          r[row.section] ||= {}
          r[row.section][row.household_category] ||= {}
          r[row.section][row.household_category][row.demographic_category] ||= {}
          r[row.section][row.household_category][row.demographic_category][row.field] ||= {}
          r[row.section][row.household_category][row.demographic_category][row.field][row.calculation] ||= {}

          r[row.section][row.household_category][row.demographic_category][row.field][row.calculation]
          if row.destination
            r[row.section][row.household_category][row.demographic_category][row.field][row.calculation][row.destination] ||= row
          else
            r[row.section][row.household_category][row.demographic_category][row.field][row.calculation][''] ||= row
          end
        end
      end
    end

    def formatted_value_for(section:, household_category:, demographic_category:, field:, calculation:, destination: nil)
      result = if destination.present?
        results_hash.dig(section.to_s, household_category.to_s, demographic_category.to_s, field.to_s, calculation.to_s, destination.to_s)
      else
        results_hash.dig(section.to_s, household_category.to_s, demographic_category.to_s, field.to_s, calculation.to_s, '')
      end
      return '' unless result

      format(result.format, result.value)
    end

    private def details_counts_for_destination(section:, household_category:, demographic_category:, field:, destination:)
      calculation = 'count_destinations'
      result = if destination.present?
        results_hash.dig(section.to_s, household_category.to_s, demographic_category.to_s, field.to_s, calculation.to_s, destination.to_s)
      else
        results_hash.dig(section.to_s, household_category.to_s, demographic_category.to_s, field.to_s, calculation.to_s, '')
      end
      result&.details || ''
    end

    def max_value_for(section)
      results.where(section: section).where.not(calculation: :count).maximum(:value)
    end
    memoize :max_value_for

    def chart_data_for(section:, household_category:, field:)
      data = measures[section]
      row_data = data[:fields][field]

      calculations = (row_data[:calculations] - [:count])
      headers = data[:headers].dup.tap { |i| i.delete_at(row_data[:calculations].find_index(:count)) } # delete_at acts on original object
      columns = {}
      counts = {}
      ([:all] + self.class.demographic_variants.keys).each do |demographic_category|
        next if exclude_variants(section, demographic_category)

        demographic_category = demographic_category.to_s
        section_columns = [['x', title_for(household_category, demographic_category)]]
        values = {}
        calculations.each.with_index do |calculation, c_idx|
          values[headers[c_idx]] ||= []
          values[headers[c_idx]] << formatted_value_for(section: section, household_category: household_category, demographic_category: demographic_category, field: field, calculation: calculation)
        end
        values.each do |k, v|
          section_columns << [k] + v
        end

        columns[demographic_category] = section_columns
        counts[title_for(household_category, demographic_category)] = formatted_value_for(section: section, household_category: household_category, demographic_category: demographic_category, field: field, calculation: :count)
      end

      all_columns = {}
      columns.values.first.each do |m|
        all_columns[m.first] ||= [m.first]
      end
      columns.values.each do |m|
        m.each do |r|
          all_columns[r.first] << r.last
        end
      end
      {
        params: [],
        one_columns: columns['all'],
        all_columns: all_columns.values,
        options: {
          height: 150,
          max: max_value_for(section),
        },
        support: {
          unit: headers,
          counts: counts['All Clients'],
          all_counts: counts,
        },
      }
    end

    def stacked_chart_data_for(section:, household_category:, field:)
      columns = {}
      detail_counts = {}
      buckets = destination_buckets.keys
      ([:all] + self.class.demographic_variants.keys).each do |demographic_category|
        next if exclude_variants(section, demographic_category)

        demographic_category = demographic_category.to_s
        section_columns = [['x', title_for(household_category, demographic_category)]]
        section_detail_counts = {}
        values = {}
        buckets.each.with_index do |destination, c_idx|
          next if destination == 'Client Count'
          # Eliminate Remained Housed if not 7b2
          next if section == 'Measure 7' && buckets[c_idx] == 'Remained housed' && field.to_s != 'm7b2_destination'

          values[buckets[c_idx]] ||= []
          values[buckets[c_idx]] << formatted_value_for(section: section, household_category: household_category, demographic_category: demographic_category, field: field, calculation: :count_destinations, destination: destination)
          section_detail_counts[buckets[c_idx]] = details_counts_for_destination(section: section, household_category: household_category, demographic_category: demographic_category, field: field, destination: destination)
        end
        values.each do |k, v|
          section_columns << [k] + v
        end

        columns[demographic_category] = section_columns
        detail_counts[title_for(household_category, demographic_category)] = section_detail_counts
      end

      all_columns = {}
      columns.values.first.each do |m|
        all_columns[m.first] ||= [m.first]
      end
      columns.values.each do |m|
        m.each do |r|
          all_columns[r.first] << r.last
        end
      end
      {
        params: [],
        one_columns: columns['all'],
        all_columns: all_columns.values,
        groups: [destination_buckets.keys],
        options: {
          height: 180,
          max: max_value_for(section),
        },
        support: {
          one_detail_counts: detail_counts['All Clients'],
          all_detail_counts: detail_counts,
        },
      }
    end

    def title_for(household_category, demographic_category)
      titles = [variants[household_category.to_sym][:base_variant][:name]]
      titles << self.class.demographic_variants[demographic_category.to_sym][:name] unless demographic_category.to_s == 'all'
      titles.join(' ')
    end

    private def add_clients(report_clients)
      # Work through all the SPM report variants, building up the `report_clients` as we go.
      run_spm.each do |household_category, spec|
        report = spec[:base_variant]

        # Create lists of client IDs in each demographic variant
        demographic_variant_clients = {}
        spec[:variants].each do |demographic_category, sub_spec|
          detail_variant_name = "spm_#{household_category}__#{demographic_category}"
          demographic_variant_clients[detail_variant_name] = client_ids_for_demographic_category(spec, sub_spec)
        end

        spm_fields.each do |spm_field, parts|
          cells = parts[:cells]
          cells.each do |cell|
            spm_clients = answer_clients(report[:report], *cell)
            spm_clients.each do |spm_client|
              detail_variant_name = "spm_#{household_category}__all"
              client_id = spm_client[:client_id]
              report_client = report_clients[client_id] || Client.new_with_default_values
              report_client[:client_id] = client_id
              report_client[:first_name] = spm_client[:first_name]
              report_client[:last_name] = spm_client[:last_name]
              report_client[:report_id] = id
              report_client["spm_#{spm_field}"] = spm_client[spm_field]
              report_client[field_name(cell)] = true if field_measure(spm_field) == 7
              report_client[detail_variant_name] = report[:report].id # SPM ID for future reference
              report_clients[client_id] = report_client

              # Set demographic flags
              demographic_variant_clients.each do |demographic_variant_name, client_ids|
                next unless client_id.in?(client_ids)

                report_client[demographic_variant_name] = 1
              end
            end
          end
        end
      end

      # With all the fields populated we need to process `exited_from_homeless_system`
      report_clients = report_clients.transform_values! do |client|
        client.spm_exited_from_homeless_system = (
            client.spm_m7a1_c3 ||
            client.spm_m7a1_c4 ||
            client.spm_m7b1_c3
          ) && !client.spm_m7b2_c3
        client
      end

      Client.import(
        report_clients.values,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: Client.attribute_names.map(&:to_sym),
        },
      )
      universe.add_universe_members(report_clients)
    end

    # This needs to temporarily set @filter to something useful for further limiting the default
    # filter set.  When it's done, it can just clear it as calling `filter` will reset it from
    # the chosen options
    private def client_ids_for_demographic_category(spec, sub_spec)
      @filter = filter

      # Force date range from measure 2 because it has the largest date range, and we
      # only use this to check to see if someone existed in a demographic category
      @filter.update(start: @filter.start - 2.years)

      # Update filter with demographic values
      base_variant = spec[:base_variant] # household type and age ranges
      extra_filters = base_variant[:extra_filters] || {} # demographics
      @filter.update(extra_filters.merge(sub_spec[:extra_filters] || {}))

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @filter.effective_project_ids

      # Apply HUD filters
      scope = @filter.apply(report_scope_source)

      # Filter for range
      scope = filter_for_range(scope)

      # Filter for demographics, to catch any demo filters that aren't applied with HudFilterBase.apply
      sub_spec[:demographic_filters].each do |demographic_filter|
        # demographic_filter is a method known to filter_scopes
        scope = send(demographic_filter, scope)
      end

      ids = scope.pluck(:client_id).uniq.to_set

      @filter = nil
      filter
      ids
    end

    private def field_name(cell)
      "spm_m#{cell.join('_')}".delete('.').downcase.to_sym
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.map(&:universe_membership)
    end

    private def run_spm
      # puts 'Running SPM'
      questions = [
        'Measure 1',
        'Measure 2',
        'Measure 7',
      ]
      options = filter.to_h
      generator = HudSpmReport::Generators::Fy2020::Generator
      variants.each do |_, spec|
        base_variant = spec[:base_variant]
        extra_filters = base_variant[:extra_filters] || {}
        processed_filter = ::Filters::HudFilterBase.new(user_id: filter.user_id)
        processed_filter.update(options.deep_merge(extra_filters))
        report = HudReports::ReportInstance.from_filter(
          processed_filter,
          generator.title,
          build_for_questions: questions,
        )
        generator.new(report).run!(email: false, manual: false)
        spec[:base_variant][:report] = report
      end
      # return @variants with reports for each question
      variants
    end

    def measures
      {
        'Measure 1' => {
          fields: m1_fields,
          headers: [
            'Client Count',
            'Average Days',
            'Median Days',
          ],
          description: 'Length of Time Clients Remain Homeless',
        },
        'Measure 2' => {
          fields: m2_fields,
          headers: [
            'Client Count',
            '% in Category',
          ],
          description: 'The Extent to which Clients Who Exit Homelessness to Permanent Housing Destinations Return to Homelessness within 6, 12, and 24 months',
        },
        'Measure 7' => {
          fields: m7_fields,
          headers: destination_buckets.keys + ::HUD.valid_destinations.map { |id, d| "#{d} (#{id})" },
          description: 'Successful Placement from Street Outreach and Successful Placement in or Retention of Permanent Housing',
        },
      }
      # Measure 1 is table with Client Count, Average Days, Median Days
      # Measure 2 is table with Client Count, % in each category
      # Measure 7 is table with Client Count, Permanent Destination Count, Temporary Destination Count, Permanent Unknown count,
      # Measure 7 is table with Client Count, column for count of every destination
    end

    private def destination_buckets
      {
        'Client Count' => [],
        'Homeless Destinations' => [16, 1, 18], # HUD.homeless_destinations,
        'Permanent Destinations' => HUD.permanent_destinations,
        'Temporary Destinations' => [2, 12, 13, 14, 27, 29, 32], # NOTE: this should probably be HUD.temporary_destinations, but HUD doesn't define homeless destinations, and some temporary destinations are also institutional, so we'll place them here.
        'Institutional Destinations' => [4, 5, 6, 7, 15, 25], # HUD.institutional_destinations,
        'Unknown, doesn\'t know, refused, or not collected' => HUD.other_destinations,
        'Remained housed' => [0], # include those who remained housed for 7b2
      }.freeze
    end

    def destinations
      @destinations ||= destination_buckets.values.select(&:present?) + HUD.valid_destinations.keys
    end

    def field_measure(field)
      return 1 if field.start_with?('m1')
      return 2 if field.start_with?('m2')
      return 7 if field.start_with?('m7') || field.start_with?('exited')
    end

    def m1_fields
      spm_fields.filter { |f, _| field_measure(f) == 1 }
    end

    def m2_fields
      {
        m2_reentry_days: {
          title: 'exiting to Permanent Destinations Within 2 Years Prior to Report Start',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
        m2_reentry_0_to_180_days: {
          title: 'Re-entering within 6 months',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
        m2_reentry_181_to_365_days: {
          title: 'Re-entering within 6-12 months',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
        m2_reentry_366_to_730_days: {
          title: 'Re-entering within 1-2 years',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
      }
    end

    def m7_fields
      spm_fields.filter { |f, _| field_measure(f) == 7 }
    end

    def spm_fields
      {
        m1a_es_sh_days: {
          cells: [['1a', 'C2']],
          title: 'with ES or SH stays',
          calculations: [:count, :average, :median],
        },
        m1a_es_sh_th_days: {
          cells: [['1a', 'C3']],
          title: 'with ES, SH, or TH stays',
          calculations: [:count, :average, :median],
        },
        m1b_es_sh_ph_days: {
          cells: [['1b', 'C2']],
          title: 'with ES, SH, or PH stays',
          calculations: [:count, :average, :median],
        },
        m1b_es_sh_th_ph_days: {
          cells: [['1b', 'C3']],
          title: 'with ES, SH, TH, or PH stays',
          calculations: [:count, :average, :median],
        },
        m2_reentry_days: {
          cells: [['2', 'B7']],
          title: 'Re-Entering Homelessness',
        },
        m7a1_destination: {
          cells: [
            ['7a.1', 'C2'],
            ['7a.1', 'C3'],
            ['7a.1', 'C4'],
          ],
          title: 'who exit Street Outreach',
          calculations: [:count, :count_destinations],
        },
        m7b1_destination: {
          cells: [
            ['7b.1', 'C2'],
            ['7b.1', 'C3'],
          ],
          title: 'in ES, SH, TH, and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
          calculations: [:count, :count_destinations],
        },
        m7b2_destination: {
          cells: [
            ['7b.2', 'C2'],
            ['7b.2', 'C3'],
          ],
          title: 'in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
          calculations: [:count, :count_destinations],
        },
      }.
        freeze
    end

    def variants
      @variants ||= self.class.report_variants
    end

    def variant_name(variant)
      @variant_names ||= {}.tap do |names|
        variants.each do |variant_slug, details|
          names["#{variant_slug}__all"] = details[:base_variant][:name]
          details[:variants].each do |sub_variant_slug, sub_details|
            names["#{variant_slug}__#{sub_variant_slug}"] = sub_details[:name]
          end
        end
      end
      @variant_names[variant]
    end

    def self.report_variants
      household_types = {
        all_persons: {
          base_variant: {
            name: 'All Clients',
            extra_filters: {
              household_type: :all,
            },
          },
          variants: {},
        },
        without_children: {
          base_variant: {
            name: 'Clients in Adult Only Households',
            extra_filters: {
              household_type: :without_children,
            },
          },
          variants: {},
        },
        with_children: {
          base_variant: {
            name: 'Clients in Adult/Child Households',
            extra_filters: {
              household_type: :with_children,
            },
          },
          variants: {},
        },
        only_children: {
          base_variant: {
            name: 'Clients in Child Only Households',
            extra_filters: {
              household_type: :only_children,
            },
          },
          variants: {},
        },
        without_children_and_fifty_five_plus: {
          base_variant: {
            name: 'Clients in Adult Only Households who are Age 55+',
            extra_filters: {
              household_type: :without_children,
              age_ranges: [
                :fifty_five_to_fifty_nine,
                :sixty_to_sixty_one,
                :over_sixty_one,
              ],
            },
          },
          variants: {},
        },
        adults_with_children_where_parenting_adult_18_to_24: {
          base_variant: {
            name: 'Clients in Adult/Child Households where the Parenting Adult is 18-24',
            extra_filters: {
              household_type: :with_children,
              hoh_only: true,
              age_ranges: [
                :eighteen_to_twenty_four,
              ],
            },
          },
          variants: {},
        },
      }
      household_types.each do |_, reports|
        demographic_variants.each do |key, variant|
          reports[:variants][key] = variant
        end
      end
      household_types.freeze
    end

    def self.available_variants
      [].tap do |av|
        report_variants.keys.each do |variant|
          av << "#{variant}__all"
          report_variants.values.flat_map { |m| m[:variants].keys }.each do |sub_v|
            av << "#{variant}__#{sub_v}"
          end
        end
      end
    end

    def self.demographic_variants
      {
        non_hispanic_latino: {
          name: HUD.ethnicity(0), # non-hispanic latino
          extra_filters: {
            ethnicities: [0],
          },
          demographic_filters: [:filter_for_ethnicity],
        },
        hispanic_latino: {
          name: HUD.ethnicity(1), # hispanic lation
          extra_filters: {
            ethnicities: [1],
          },
          demographic_filters: [:filter_for_ethnicity],
        },
        black_african_american: {
          name: HUD.race('BlackAfAmerican'),
          extra_filters: {
            races: ['BlackAfAmerican'],
          },
          demographic_filters: [:filter_for_race],
        },
        asian: {
          name: HUD.race('Asian'),
          extra_filters: {
            races: ['Asian'],
          },
          demographic_filters: [:filter_for_race],
        },
        american_indian_alaskan_native: {
          name: HUD.race('AmIndAKNative'),
          extra_filters: {
            races: ['AmIndAKNative'],
          },
          demographic_filters: [:filter_for_race],
        },
        native_hawaiian_other_pacific_islander: {
          name: HUD.race('NativeHIPacific'),
          extra_filters: {
            races: ['NativeHIPacific'],
          },
          demographic_filters: [:filter_for_race],
        },
        white: {
          name: HUD.race('White'),
          extra_filters: {
            races: ['White'],
          },
          demographic_filters: [:filter_for_race],
        },
        multi_racial: {
          name: HUD.race('MultiRacial'),
          extra_filters: {
            races: ['MultiRacial'],
          },
          demographic_filters: [:filter_for_race],
        },
        race_none: {
          name: 'Unknown Race',
          extra_filters: {
            races: ['RaceNone'],
          },
          demographic_filters: [:filter_for_race],
        },

        b_n_h_l: {
          name: [HUD.race('BlackAfAmerican'), HUD.ethnicity(0)].join(' '),
          extra_filters: {
            ethnicities: [0],
            races: ['BlackAfAmerican'],
          },
          demographic_filters: [:filter_for_ethnicity, :filter_for_race],
        },
        a_n_h_l: {
          name: [HUD.race('Asian'), HUD.ethnicity(0)].join(' '),
          extra_filters: {
            ethnicities: [0],
            races: ['Asian'],
          },
          demographic_filters: [:filter_for_ethnicity, :filter_for_race],
        },
        n_n_h_l: {
          name: [HUD.race('AmIndAKNative'), HUD.ethnicity(0)].join(' '),
          extra_filters: {
            ethnicities: [0],
            races: ['AmIndAKNative'],
          },
          demographic_filters: [:filter_for_ethnicity, :filter_for_race],
        },
        h_n_h_l: {
          name: [HUD.race('NativeHIPacific'), HUD.ethnicity(0)].join(' '),
          extra_filters: {
            ethnicities: [0],
            races: ['NativeHIPacific'],
          },
          demographic_filters: [:filter_for_ethnicity, :filter_for_race],
        },
        white_non_hispanic_latino: {
          name: [HUD.race('White'), HUD.ethnicity(0)].join(' '),
          extra_filters: {
            ethnicities: [0],
            races: ['White'],
          },
          demographic_filters: [:filter_for_ethnicity, :filter_for_race],
        },
        fleeing_dv: {
          name: 'Currently Fleeing DV',
          extra_filters: {
            currently_fleeing: [1],
          },
          demographic_filters: [:filter_for_dv_currently_fleeing],
        },
        veteran: {
          name: 'Veterans',
          extra_filters: {
            veteran_statuses: [1],
          },
          demographic_filters: [:filter_for_veteran_status],
        },
        has_disability: {
          name: 'With Indefinite and Impairing Disability',
          extra_filters: {
            indefinite_disabilities: [1],
          },
          demographic_filters: [:filter_for_indefinite_disabilities],
        },
        has_rrh_move_in_date: {
          name: 'Moved in to RRH',
          extra_filters: {
            rrh_move_in: true,
          },
          demographic_filters: [:filter_for_rrh_move_in],
        },
        has_psh_move_in_date: {
          name: 'Moved in to PSH',
          extra_filters: {
            psh_move_in: true,
          },
          demographic_filters: [:filter_for_psh_move_in],
        },
        first_time_homeless: {
          name: 'First Time Homeless in Past Two Years',
          extra_filters: {
            first_time_homeless: true,
          },
          demographic_filters: [:filter_for_first_time_homeless_in_past_two_years],
        },
        # NOTE: only display this on Measure 1 (it will never work on Measure 2)
        returned_to_homelessness_from_permanent_destination: {
          name: 'Returned to Homelessness from Permanent Destination',
          extra_filters: {
            returned_to_homelessness_from_permanent_destination: true,
          },
          demographic_filters: [:filter_for_returned_to_homelessness_from_permanent_destination],
        },
      }.
        freeze
    end

    def exclude_variants(measure_name, variant)
      @exclude_variants ||= {
        'Measure 2' => [:returned_to_homelessness_from_permanent_destination],
        'Measure 7' => [:returned_to_homelessness_from_permanent_destination],
      }
      @exclude_variants[measure_name.to_s]&.include?(variant.to_sym)
    end

    def calculate(variant, field, calculation, options)
      cell = "spm_#{field}"
      scope = clients.send(variant).send(cell)

      value = case calculation

      when :count
        scope.count
      when :average
        scope.average(cell)
      when :median
        scope.median(cell)
      when :percent
        # denominator should always be the "all" variant
        denominator = clients.send('spm_all_persons__all').send(options[:total]).count
        (scope.count / denominator.to_f) * 100 unless denominator.zero?
      when :count_destinations
        rc_t = Client.arel_table
        scope.where(rc_t[cell].in(Array.wrap(options[:destination]))).count
      end
      value&.round(1) || 0
    end
    memoize :calculate
  end
end
