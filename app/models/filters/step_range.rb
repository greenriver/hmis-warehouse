module Filters
  class StepRange < ::ModelForm
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