###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# A HUD Report instance, identified by report name (e.g., report_name: 'CE APR - 2020')
module HudReports
  class ReportInstance < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = 'hud_report_instances'

    belongs_to :user
    has_many :report_cells, dependent: :destroy
    has_many :universe_cells, -> do
      universe
    end, class_name: 'ReportCell'

    def current_status
      case state
      when 'Waiting'
        'Queued to start'
      when 'Started'
        if started_at.present? && started_at < 24.hours.ago
          'Failed'
        else
          if started_at.present?
            "#{state} at #{started_at}"
          else
            state
          end
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
    def start(question, tables)
      universe(question).update(status: 'Started', metadata: {tables: tables})
      update(state: 'Started', started_at: Time.current) if state.blank?
    end

    # Mark a question as completed
    #
    # @param question [String] the question name (e.g., 'Question 1')
    def complete(question)
      universe(question).update(status: 'Completed')
      update(state: 'Completed', completed_at: Time.current) if running?
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
      report_cells.
        where(question: question, universe: true).
        first_or_create
    end

    def included_questions
      universe_cells.map(&:question)
    end
  end
end
