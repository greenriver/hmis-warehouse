###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module LongitudinalSpm
  class Report < GrdaWarehouseBase
    self.table_name = :longitudinal_spms
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include SpmBasedReports
    include Rails.application.routes.url_helpers

    acts_as_paranoid

    after_initialize :filter

    belongs_to :user
    has_many :spms
    has_many :hud_spms, through: :spms
    has_many :results

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
        run_spms
        populate_results
      rescue Exception => e
        update(failed_at: Time.current, processing_errors: e.message)
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

    def url
      longitudinal_spm_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      'Longitudinal System Performance Measures'
    end

    def description
      "System Performance Report comparisons for the four quarters prior to #{filter.end_date}."
    end

    def filter
      @filter ||= ::Filters::HudFilterBase.new(
        user_id: user_id,
        enforce_one_year_range: false,
      ).update(options)
    end

    def report_path_array
      [
        :longitudinal_spm,
        :warehouse_reports,
        :reports,
      ]
    end

    def describe_filter_as_html
      filter.describe_filter_as_html(
        [
          :end,
          :comparison_pattern,
          :coc_code,
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
          :funder_ids,
          :hoh_only,
        ],
      )
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    private def build_control_sections
      # ensure filter has been set
      filter
      [
        build_funding_section,
        build_hoh_control_section,
      ]
    end

    private def populate_results
      Result.where(report_id: id).delete_all
      spms.each do |spm|
        spm_measures.each do |measure, tables|
          tables.each do |table, cells|
            cells.each do |cell|
              results.create!(
                spm_id: spm.id,
                start_date: spm.start_date,
                end_date: spm.end_date,
                measure: measure,
                table: table,
                cell: cell,
                value: spm.hud_spm.answer(question: table, cell: cell).summary,
              )
            end
          end
        end
      end
    end

    def spm_describe(measure_or_table, cell = nil, row_col = :row)
      return spm_generator.describe_table(measure_or_table) if cell.blank?

      @sample_spm ||= spms.first.hud_spm # Just find one of the SPMs so we can get metadata
      row = cell.gsub(/\D/, '').to_i - 2 # cells are 1 based, rows 0 based and the first row is ignored
      return @sample_spm.answer(question: measure_or_table).metadata['row_labels'][row] if row_col == :row

      col = cell.gsub(/\d/, '').ord - 65 # ascii ordinal math (turns A -> 0, B -> 1, etc.)
      @sample_spm.answer(question: measure_or_table).metadata['header_row'][col]
    end

    def chart_data(measure, table, cell)
      data = [spm_describe(table, cell, :col)]
      results.select { |m| m.measure == measure && m.table == table && m.cell == cell }.
        sort_by(&:end_date).
        map do |result|
          data << result.value
        end
      [
        ['x'] + quarter_dates.map { |m| m[:end] }.sort,
        data,
      ]
    end

    def spm_measures
      {
        'Measure 1' => {
          '1a' => [
            'E2',
            'E3',
          ],
          '1b' => [
            'E2',
            'E3',
          ],
        },
        'Measure 2' => {
          '2' => [
            'J2',
            'J3',
            'J4',
            'J5',
            'J6',
            'J7',
          ],
        },
        'Measure 7' => {
          '7a.1' => [
            'C5',
          ],
          '7b.1' => [
            'C4',
          ],
          '7b.2' => [
            'C4',
          ],
        },
      }.freeze
    end

    private def quarter_dates
      @quarter_dates ||= [].tap do |quarters|
        end_date = filter.end_date
        4.times do |i|
          date = end_date << (i * 3) # move date back 3 months * iteration
          date = date.end_of_quarter
          quarters << {
            start: date - 1.years + 1.days,
            end: date,
          }
        end
      end
    end

    private def run_spms
      Spm.where(report_id: id).delete_all
      options = filter.to_h
      quarter_dates.each do |dates|
        spm_filter = ::Filters::HudFilterBase.new(user_id: user_id)
        spm_filter.update(options.deep_merge(dates))
        report = HudReports::ReportInstance.from_filter(
          spm_filter,
          spm_generator.title,
          build_for_questions: spm_measures.keys,
        )
        spm_generator.new(report).run!(email: false, manual: false)
        spms.create(report_id: id, spm_id: report.id, start_date: dates[:start], end_date: dates[:end])
      end
    end

    private def spm_generator
      HudSpmReport::Generators::Fy2020::Generator
    end
  end
end
