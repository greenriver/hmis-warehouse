###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'

module PerformanceMeasurement
  class Report < SimpleReports::ReportInstance
    extend Memoist
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    acts_as_paranoid

    belongs_to :user
    has_many :clients

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
        create_universe
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

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id)
        f.update(options.with_indifferent_access) if options.present?
        f
      end
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'performance_measurement/warehouse_reports/report'
    end

    def url
      performance_measurement_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('Performance Measurement Dashboard')
    end

    def multiple_project_types?
      true
    end

    def default_project_types
      [:ph, :es, :th, :sh, :so]
    end

    def report_path_array
      [
        :performance_measurement,
        :warehouse_reports,
        :reports,
      ]
    end

    # @return filtered scope
    def report_scope
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    private def create_universe
      report_clients = {}
      add_clients(report_clients)
    end

    private def add_clients(report_clients)
      # Run CoC-wide SPMs for year prior to selected date and period 2 years prior
      # add records for each client to indicate which projects they were enrolled in within the report window
      run_spm.each do |variant_name, spec|
        { '' => spec[:base_variant] }.merge(spec[:variants]).each do |sub_variant, report|
          detail_variant_name = "spm_#{variant_name}__#{sub_variant.presence || 'all'}"
          spm_fields.each do |spm_field, parts|
            cells = parts[:cells]
            cells.each do |cell|
              spm_clients = answer_clients(report[:report], *cell)
              spm_clients.each do |spm_client|
                report_client = report_clients[spm_client[:client_id]] || Client.new
                report_client[:client_id] = spm_client[:client_id]
                report_client[:first_name] = spm_client[:first_name]
                report_client[:last_name] = spm_client[:last_name]
                report_client[:report_id] = id
                report_client["spm_#{spm_field}"] = spm_client[spm_field]
                if field_measure(spm_field) == 7
                  field_name = "spm_m#{cell.join('_')}".delete('.').downcase.to_sym
                  report_client[field_name] = true
                end
                report_client[detail_variant_name] = report[:report].id
                report_clients[spm_client[:client_id]] = report_client
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
        'Measure 3',
        'Measure 4',
        'Measure 5',
        'Measure 7',
      ]
      # NOTE: we need to include all homeless projects visible to this user, plus the chosen scope,
      # so that the returns calculation will work.
      options = filter.to_h
      options[:project_type_codes] ||= []
      options[:project_type_codes] += [:es, :so, :sh, :th]
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

        spec[:variants].each do |_, sub_spec|
          processed_filter = ::Filters::HudFilterBase.new(user_id: filter.user_id)
          processed_filter.update(options.deep_merge(extra_filters.merge(sub_spec[:extra_filters] || {})))
          report = HudReports::ReportInstance.from_filter(
            processed_filter,
            generator.title,
            build_for_questions: questions,
          )
          generator.new(report).run!(email: false, manual: false)
          sub_spec[:report] = report
        end
      end
      # return @variants with reports for each question
      variants
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
            name: 'All Persons',
            extra_filters: {
              household_type: :all,
            },
          },
          variants: {},
        },
        with_children: {
          base_variant: {
            name: 'Persons in Adult/Child Households',
            extra_filters: {
              household_type: :with_children,
            },
          },
          variants: {},
        },
        only_children: {
          base_variant: {
            name: 'Persons in Child Only Households',
            extra_filters: {
              household_type: :only_children,
            },
          },
          variants: {},
        },
        without_children_and_fifty_five_plus: {
          base_variant: {
            name: 'Persons in Adult Only Households who are Age 55+',
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
            name: 'Adults in Adult/Child Households where the Parenting Adult is 18-24',
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
        white_non_hispanic_latino: {
          name: 'White Non-Hispanic/Non-Latin(a)(o)(x) Persons',
          extra_filters: {
            ethnicities: [HUD.ethnicity('Non-Hispanic/Non-Latin(a)(o)(x)', true)],
            races: ['White'],
          },
        },
        hispanic_latino: {
          name: 'Hispanic/Latin(a)(o)(x)',
          extra_filters: {
            ethnicities: [HUD.ethnicity('Hispanic/Latin(a)(o)(x)', true)],
          },
        },
        black_african_american: {
          name: 'Black/African American Persons',
          extra_filters: {
            races: ['BlackAfAmerican'],
          },
        },
        asian: {
          name: 'Asian Persons',
          extra_filters: {
            races: ['Asian'],
          },
        },
        american_indian_alaskan_native: {
          name: 'American Indian/Alaskan Native Persons',
          extra_filters: {
            races: ['AmIndAKNative'],
          },
        },
        native_hawaiian_other_pacific_islander: {
          name: 'Native Hawaiian or Pacific Islander',
          extra_filters: {
            races: ['NativeHIPacific'],
          },
        },
        multi_racial: {
          name: 'Multiracial',
          extra_filters: {
            races: ['MultiRacial'],
          },
        },
        fleeing_dv: {
          name: 'Currently Fleeing DV',
          extra_filters: {
            currently_fleeing: [1],
          },
        },
        veteran: {
          name: 'Veterans',
          extra_filters: {
            veteran_statuses: [1],
          },
        },
        has_disability: {
          name: 'With Indefinite and Impairing Disability',
          extra_filters: {
            indefinite_disabilities: [1],
          },
        },
        has_rrh_move_in_date: {
          name: 'Moved in to RRH',
          extra_filters: {
            rrh_move_in: true,
          },
        },
        has_psh_move_in_date: {
          name: 'Moved in to PSH',
          extra_filters: {
            psh_move_in: true,
          },
        },
        first_time_homeless: {
          name: 'First Time Homeless in Past Two Years',
          extra_filters: {
            first_time_homeless: true,
          },
        },
        # NOTE: only display this on Measure 1 (it will never work on Measure 2)
        returned_to_homelessness_from_permanent_destination: {
          name: 'Returned to Homelessness from Permanent Destination',
          extra_filters: {
            returned_to_homelessness_from_permanent_destination: true,
          },
        },
      }.freeze
    end

    def exclude_variants(measure_name, variant)
      @exclude_variants ||= {
        'Measure 2' => [:returned_to_homelessness_from_permanent_destination],
        'Measure 7' => [:returned_to_homelessness_from_permanent_destination],
      }
      @exclude_variants[measure_name.to_s]&.include?(variant)
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
        # spm_m7a1_destination
        rc_t = Client.arel_table
        scope.where(
          rc_t[:spm_m7a1_destination].in(Array.wrap(options[:destination])).
          or(rc_t[:spm_m7b1_destination].in(Array.wrap(options[:destination]))),
        ).count
      end
      value&.round(1) || 0
    end
    memoize :calculate
  end
end
