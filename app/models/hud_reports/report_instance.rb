###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
        coc_code: filter.coc_code,
        options: filter.for_params[:filters].slice(:start, :end, :coc_code, :project_ids, :project_group_ids, :user_id),
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

    # Mark a question as started
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @param tables [Array<String>] the names of the tables in a question
    # FIXME: maybe a single question column on report_instance to track if this is a single
    # question run or all questions.... Need bater start/complete logic
    def start(question, tables)
      universe(question).update(status: 'Started', metadata: {tables: tables})
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

    def existing_universe(question)
      report_cells.find_by(question: question, universe: true)
    end

    private def universe_scope(question)
      report_cells.where(question: question, universe: true)
    end

    def included_questions
      universe_cells.map(&:question)
    end

    def valid_cell_name(cell_name)
      cell_name.match(/\w{1,2}\d{1,2}/).to_s
    end

    def valid_table_name(table)
      table.match(/\w{1,2}\d{1,2}\w{0,1}/).to_s
    end
  end
end
