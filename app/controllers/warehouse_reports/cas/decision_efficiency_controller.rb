module WarehouseReports::Cas
  class DecisionEfficiencyController < ApplicationController
    include ArelHelper

    before_action :require_can_view_reports!, :load_vars

    def index
      
    end

    def chart
      render json: @data, layout: false
    end

    def date_range_options
      options = params.permit(steps: [:start, :end])[:steps]
      unless options.present?
        options = {
          start: 12.month.ago.to_date,
          end: Date.today,
        }
      end
      options
    end

    private def load_vars
      @range = DateRange.new(date_range_options)
      @step_range = StepRange.new(step_params)
      @data = {}
      if @step_range.first.present?
        histogram = step_time_histogram(@step_range)
        @data[:labels] = histogram.keys
        @data[:data_sets] = histogram.values.map(&:keys).flatten.uniq.map do |title|
          values = histogram.keys.map do |key|
            histogram[key].try(:[], title) || 0 
          end
          [title, values]
        end.to_h
        n = histogram.values.map(&:values).flatten.sum
        counts = []
        histogram.values.map(&:values).map(&:sum).each_with_index do |count, index|
          counts << [index] * count
        end
        counts.flatten!
        mean = (counts.sum.to_f / counts.length).round(2)
        stddev = 0
        counts.each do |point|
          stddev += ( point - mean ) ** 2
        end
        stddev /= counts.length - 1
        stddev = Math.sqrt(stddev)
        stddev = stddev.round(2)
        @data[:stats] = {
          n: n,
          minimum: histogram.keys.first,
          maximum: histogram.keys.last,
          median: median(counts),
          mean: mean,
          standard_deviation: stddev,
        }
      end
    end

    def median array
      mid = array.size / 2
      sorted = array.sort
      array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2 
    end

    private def step_params
      return {} unless params.has_key? :steps
      params.require(:steps).permit(:first, :second, :unit)
    end

    # creates a histogram mapping intervals to numbers of occurrences
    private def step_time_histogram(step_range)
      first_step  = step_range.first.gsub(/\(\d+\)/,'').strip
      second_step = step_range.second.gsub(/\(\d+\)/,'').strip
      unit        = step_range.unit
      divisor = case unit
      when 'second'
        1
      when 'minute'
        60
      when 'hour'
        60 * 60
      when 'day'
        24 * 60 * 60
      when 'week'
        7 * 24 * 60 * 60
      else
        raise "unanticipated time unit: #{unit}"
      end
      at = GrdaWarehouse::CasReport.arel_table
      at2 = Arel::Table.new at.table_name
      at2.table_alias = 'at2'
      query = at.where(at[:match_started_at].between(@range.start..@range.end+1.day)).
        join(at2).on(
        at[:client_id].eq(at2[:client_id]).and(
          at[:match_id].eq at2[:match_id]
        ).and(
          at[:match_step].eq first_step
        ).and(
          at2[:match_step].eq second_step
        )
      ).where(at2[:match_started_at].between(@range.start..@range.end+1.day)).
      project(
        seconds_diff( at.engine, at2[:updated_at], at[:updated_at] ),
        at[:program_type]
      )
      times = at.engine.connection.select_rows(query.to_sql).map do |time_diff, program_type|
        [(time_diff.to_f / divisor).round.to_i, program_type]
      end
      return {} if times.empty?
      min, max = times.map{|secs, _| secs}.minmax
      histogram = times.group_by(&:first).map do |bucket,rows|
        grouped_counts = {}
        rows.each do |_, project_type|
          grouped_counts[bucket] ||= {}
          grouped_counts[bucket][project_type] ||= 0
          grouped_counts[bucket][project_type] += 1
        end
        [bucket, grouped_counts[bucket]]
      end.to_h
      (min..max).each{ |v| histogram[v] ||= {} }
      histogram.sort_by(&:first).to_h
    end

    class StepRange < ModelForm
      attribute :first,  String, lazy: true, default: -> (o,_) { o.ordered_steps&.first&.first }
      attribute :second, String, lazy: true, default: -> (o,_) { o.ordered_steps[o&.first]&.first }
      attribute :unit,   String, default: 'day'

      def units
        if Rails.env.development?
          %w( week day hour minute second )
        else
          %w( week day )
        end
      end

      # hash from steps to steps that may follow them
      def ordered_steps
        @ordered_steps ||= begin
          scope = GrdaWarehouse::CasReport#.started_between(start_date: @range.start, end_date: @range.end + 1.day)
          steps = scope.uniq.order(:match_step).pluck :match_step
          at = scope.arel_table
          at2 = Arel::Table.new at.table_name
          at2.table_alias = 'at2'
          followups = steps.map do |step|
            followups = scope.where(
              at2.project(Arel.star).
                where( at2[:client_id].      eq at[:client_id] ).
                where( at2[:match_id].       eq at[:match_id] ).
                where( at2[:decision_order]. lt at[:decision_order] ).
                where( at2[:match_step].     eq step ).
                exists
            ).distinct.pluck(:match_step)
            [ step, followups ]
          end.to_h
          step_order = followups.keys.sort do |a,b|
            if followups[a].include?(b)
              -1
            elsif followups[b].include?(a)
              1
            else
              0
            end
          end.each_with_index.to_h
          followups.select{ |_,ar| ar.any? }.sort_by{ |a,_| step_order[a] }.map{ |a,ar| [ "(#{step_order[a] + 1}) #{a}", ar.sort_by{ |s| step_order[s] }.map{|s| "(#{step_order[s] + 1}) #{s}"} ] }.to_h
        end
      end
    end
  end
end