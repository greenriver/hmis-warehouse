###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Results::EventType < CePerformance::Result
    include CePerformance::Results::Calculations
    # Count all events by event type
    def self.calculate(report, period)
      events = {}
      client_scope(report, period).find_each do |client|
        client.events&.each do |event|
          events[event['event']] ||= 0
          events[event['event']] += 1
        end
      end
      available_event_ids.each do |event_id|
        count = events[event_id] || 0
        create(
          report_id: report.id,
          period: period,
          value: count,
          event_type: event_id,
        )
      end
    end

    def self.client_scope(report, period)
      report.clients.served_in_period(period).where.not(events: nil)
    end

    # TODO: move to goal configuration
    def self.goal
      nil
    end

    def display_goal?
      false
    end

    def unit
      'events'
    end

    def self.ce_apr_question
      'Question 9'
    end

    def self.title
      _('Number and Types of CE Events ')
    end

    def self.available_event_ids
      ::HUD.events.keys
    end

    def category
      'Activity'
    end

    def self.description
      ''
    end

    def self.calculation
      'Counts of events by type occurring during the reporting range.'
    end

    def detail_link_text
      'Event details'
    end

    def indicator(comparison)
      @indicator ||= OpenStruct.new(
        primary_value: value.to_i,
        primary_unit: unit,
        secondary_value: percent_change_over_year(comparison),
        secondary_unit: '%',
        value_label: 'change over year',
        passed: passed?(comparison),
        direction: direction(comparison),
      )
    end

    def percentage?
      false
    end

    def data_for_chart(report, _comparison)
      report_year_data = report.results.where.not(event_type: nil).pluck(:event_type, :value).to_h
      comparison_year_data = {}
      # if comparison.present?
      #   comparison.where.not(event_type: nil).pluck(:event_type, :value).to_h
      # else
      #   {}
      # end

      # normalize data
      comparison_year_data.keys.each do |k|
        report_year_data[k] ||= 0
      end
      report_year_data.keys.each do |k|
        comparison_year_data[k] ||= 0
      end
      report_year_data.to_h.sort
      comparison_year_data.to_h.sort

      columns = []
      x = ['x']
      report_year_data.each do |k, count|
        columns << [::HUD.event(k), count]
        x << ::HUD.event(k)
      end
      columns << x
      {
        x: 'x',
        columns: columns,
        type: 'bar',
        labels: {
          colors: 'white',
          centered: true,
        },
      }
    end
  end
end
