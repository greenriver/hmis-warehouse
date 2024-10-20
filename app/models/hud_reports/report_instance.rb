###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A HUD Report instance, identified by report name (e.g., report_name: 'CE APR - 2020')
module HudReports
  class ReportInstance < GrdaWarehouseBase
    acts_as_paranoid
    include ActionView::Helpers::DateHelper
    include SafeInspectable
    include RailsDrivers::Extensions

    self.table_name = 'hud_report_instances'

    belongs_to :user, optional: true
    has_many :report_cells # , dependent: :destroy # for the moment, this is too slow
    has_many :universe_cells, -> do
      universe
    end, class_name: 'ReportCell'
    scope :manual, -> { where(manual: true) }
    scope :automated, -> { where(manual: false) }
    scope :complete, -> { where.not(completed_at: nil) }
    scope :incomplete, -> { where(completed_at: nil) }
    scope :started, -> { where(state: 'Started') }
    scope :created_recently, -> { where(created_at: 24.hours.ago .. Time.current) }
    scope :diet, -> { select(column_names - ['options', 'project_ids', 'build_for_questions', 'question_names']) }
    scope :for_report, ->(report_name) { where(report_name: report_name) }

    def self.from_filter(filter, report_name, build_for_questions:)
      new(
        report_name: report_name,
        build_for_questions: build_for_questions,
        remaining_questions: build_for_questions,
        user_id: filter.user_id,
        project_ids: filter.effective_project_ids,
        start_date: filter.start.to_date,
        end_date: filter.end.to_date,
        coc_codes: filter.coc_codes,
        options: filter.to_h,
      )
    end

    def current_status
      # Sometimes the report attempts to run again and ends up in the Started state, short circuit if we know this
      # isn't going to run successfully
      return "Failed: #{error_details}" if error_details.present?

      case state
      when 'Waiting'
        if job_failed? || related_job.blank?
          # provide a "fast fail" if the delayed job failed or we can't find one
          'Failed'
        else
          'Queued to start'
        end
      when 'Started'
        if started_at.present? && started_at < 24.hours.ago
          'Failed'
        elsif job_failed?
          # provide a "fast fail" if the delayed job failed (and we can find one)
          'Failed'
        elsif related_job.blank?
          # if the related delayed job has been deleted, probably because it failed and was cleaned up
          'Failed'
        elsif started_at.present?
          "#{state} at #{started_at}"
        else
          state
        end
      when 'Completed'
        if started_at.present? && completed_at.present?
          "#{state} in #{distance_of_time_in_words(started_at, completed_at)} <br/> #{completed_at} ".html_safe
        else
          state
        end
      when 'Failed'
        if error_details.present?
          "#{state}: #{error_details}"
        else
          state
        end
      else
        'Failed'
      end
    end

    def failures
      report_cells.where.not(error_messages: nil).pluck(:question, :cell_name, :status, :error_messages)
    end

    private def job_failed?
      related_job.present? && related_job.failed?
    end

    def related_job
      # See if we can find a related job (this is really overloading the jobs_for_class scope, but should work)
      dj = Delayed::Job.jobs_for_class('RunReportJob').jobs_for_class(id.to_s)
      # If we didn't find an obvious match, just return nothing
      dj&.first unless dj.many?
    end

    # Mark a question as started
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @param tables [Array<String>] the names of the tables in a question
    # FIXME: maybe a single question column on report_instance to track if this is a single
    # question run or all questions.... Need better start/complete logic
    def start(question, tables)
      universe(question).update!(status: 'Started', metadata: { tables: Array(tables) })
    end

    def start_report
      update!(state: 'Started', started_at: Time.current)
    end

    # Mark a question as completed
    #
    # @param question [String] the question name (e.g., 'Question 1')
    def complete(question)
      universe(question).update!(status: 'Completed')
      complete_report if remaining_questions.empty?
    end

    def complete_report
      return if @failed

      update!(state: 'Completed', completed_at: Time.current)
    end

    def completed_questions
      report_cells.where(status: 'Completed').pluck(:question)
    end

    def completed?
      state == 'Completed'
    end

    def failed?
      current_status == 'Failed'
    end

    def running?
      return false if started_at.present? && started_at < 24.hours.ago
      return false if started_at.blank? && created_at < 24.hours.ago
      return false if failed?

      state.in?(['Waiting', 'Started'])
    end

    # Can be used to preload all answers for a question
    # Example: @report.preload_answers('Question 1').answer(question: 'Question 1', cell: 'B4')
    def preload_answers(question)
      @preload_answers ||= {}
      @preload_answers[question] ||= report_cells.where(question: question, universe: false).index_by(&:cell_name)
      self # return self to allow for chaining
    end

    # An answer cell in a question
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @param cell [String] the cell name (e.g, 'B2')
    # @return [ReportCell] the answer cell
    def answer(question:, cell: nil)
      preloaded_answer = @preload_answers.try(:[], question).try(:[], cell)
      return preloaded_answer if preloaded_answer.present?

      report_cells.
        where(question: question, cell_name: cell, universe: false).
        first_or_create
    end

    # The universe of members (such as clients) for a question
    #
    # The per-question universe allows us to explain why a given member was not included in a cell; the inverse of
    # explaining why member was included in a cell using the cell members. As of this writing this universe is not
    # exposed in the UI
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @return [ReportCell] the universe cell
    def universe(question)
      universe_scope(question).first_or_create
    end

    # DANGER. This deletes the reports data without changing its state.
    # Usefully for debugging, it should be be considered private and
    # perhaps integrated with start_report, complete_report, start(question), complete(question)
    def _purge_universe
      # clear the polymorphic graph of universe membership
      universe_members = HudReports::UniverseMember.with_deleted.
        where(report_cell_id: report_cells)

      # universe_membership_type
      universe_members.distinct.pluck(
        :universe_membership_type,
        :universe_membership_id,
      ).group_by(&:first).each do |sti_type, joins|
        klass = sti_type.constantize
        ids = joins.map(&:second)
        # purge (really delete the data)
        klass.with_deleted.where(id: ids).delete_all
      end

      # now we can kill the universe_members
      universe_members.delete_all

      # and now the cells
      report_cells.with_deleted.delete_all
    end

    def existing_universe(question)
      report_cells.find_by(question: question, universe: true)
    end

    private def universe_scope(question)
      report_cells.where(question: question, universe: true)
    end

    def included_questions
      universe_cells.map(&:question)
    end

    def generated_uploadable_version?
      question_names.include?('HDX Upload')
    end

    # only allow alpha numeric
    def valid_cell_name(cell_name)
      cell_name&.match(/[A-Z0-9]+/i).to_s
    end

    # only allow alpha numeric, and dashes
    def valid_table_name(table)
      table&.match(/[A-Z0-9-]+/i).to_s
    end

    def as_markdown
      io = StringIO.new
      question_names.each do |question|
        metadata = existing_universe(question)&.metadata
        next unless metadata

        io << "## #{question}\n"
        Array(metadata['tables']).compact.each do |table|
          io.puts "### Table: #{table}\n"

          exporter = HudReports::CsvExporter.new(self, table)
          columns = exporter.display_column_names.to_a
          rows = exporter.as_array.map { |row| row.map { |c| c.to_s.gsub(/\n/, '') } }

          io.puts "#{ANSI::Table.new [columns] + rows[1..]}\n"
        end
      end

      io.string
    end
  end
end
