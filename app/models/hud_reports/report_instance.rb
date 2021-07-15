###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A HUD Report instance, identified by report name (e.g., report_name: 'CE APR - 2020')
module HudReports
  class ReportInstance < GrdaWarehouseBase
    acts_as_paranoid
    include ActionView::Helpers::DateHelper
    self.table_name = 'hud_report_instances'

    belongs_to :user
    has_many :report_cells # , dependent: :destroy # for the moment, this is too slow
    has_many :universe_cells, -> do
      universe
    end, class_name: 'ReportCell'

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
      case state
      when 'Waiting'
        'Queued to start'
      when 'Started'
        if started_at.present? && started_at < 24.hours.ago
          'Failed'
        elsif started_at.present?
          "#{state} at #{started_at}"
        else
          state
        end
      when 'Completed'
        if started_at.present? && completed_at.present?
          "#{state} at #{completed_at} in #{distance_of_time_in_words(started_at, completed_at)}"
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

    # Mark a question as started
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @param tables [Array<String>] the names of the tables in a question
    # FIXME: maybe a single question column on report_instance to track if this is a single
    # question run or all questions.... Need bater start/complete logic
    def start(question, tables)
      universe(question).update(status: 'Started', metadata: { tables: Array(tables) })
      start_report if build_for_questions.count == remaining_questions.count
    end

    def start_report
      update(state: 'Started', started_at: Time.current)
    end

    # Mark a question as completed
    #
    # @param question [String] the question name (e.g., 'Question 1')
    def complete(question)
      universe(question).update(status: 'Completed')
      complete_report if remaining_questions.empty?
    end

    def complete_report
      update(state: 'Completed', completed_at: Time.current)
    end

    def completed_questions
      report_cells.where(status: 'Completed').pluck(:question)
    end

    def completed?
      state == 'Completed'
    end

    def running?
      return false if started_at.present? && started_at < 24.hours.ago
      return false if started_at.blank? && created_at < 24.hours.ago

      state.in?(['Waiting', 'Started'])
    end

    # An answer cell in a question
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @param cell [String] the cell name (e.g, 'B2')
    # @return [ReportCell] the answer cell
    def answer(question:, cell: nil)
      report_cells.
        where(question: question, cell_name: cell, universe: false).
        first_or_create
    end

    # The universe of clients for a question
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
      universe_members = HudReports::UniverseMember.with_deleted.where(
        report_cell_id: report_cells
      )

      # universe_membership_type
      universe_members.distinct.pluck(
        :universe_membership_type,
        :universe_membership_id
      ).group_by(&:first).each do |sti_type, joins|
        klass = sti_type.constantize
        ids = joins.map(&:second)
        # purge (really delete the data)
        klass.with_deleted.where(id: ids).delete_all
      end

      # now we can kill the unverse_members
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

    # only allow alpha numeric
    def valid_cell_name(cell_name)
      cell_name.match(/[A-Z0-9]+/i).to_s
    end

    # only allow alpha numeric, and dashes
    def valid_table_name(table)
      table.match(/[A-Z0-9-]+/i).to_s
    end


    def as_markdown
      io = StringIO.new
      question_names.each do |question|
        metadata = existing_universe(question)&.metadata
        if metadata
          io << "## #{question}\n"
          Array(metadata['tables']).compact.each do |table|
            io.puts "### Table: #{table}\n"

            exporter = HudReports::CsvExporter.new(self, table)
            columns = exporter.display_column_names.to_a
            rows = exporter.as_array.map{|row| row.map{|c| c.to_s.gsub(/\n/,'') } }

            io.puts "#{ANSI::Table.new [columns]+rows[1..]}\n"
          end
        end
      end

      io.string
    end
  end
end
