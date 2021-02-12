###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Multinomial < Field
    DESCRIPTION = <<~DESC.freeze
      _{{{human_name}}}_ measures similarity of individuals with respect to
      a property that can take one of several distinct values.
    DESC

    # the maximum additional weight given to similar items
    MAX_MULTIPLIER = 3.0 # picked by intuition rather than experiment

    def max_multiplier
      self.class::MAX_MULTIPLIER
    end

    def prepare!
      return unless GrdaWarehouse::Hud::Client.column_names.include?(field.to_s)

      counts = GrdaWarehouse::Hud::Client.source.group(field).count
      grouped = {}.tap do |each_grouped|
        counts.each do |k, v|
          if (k = group(k))
            each_grouped[k] ||= 0
            each_grouped[k] += v
          end
        end
      end
      total = grouped.values.sum
      other_state['_total'] = total
      grouped.each do |k, v|
        w = total / v.to_f
        w = MAX_MULTIPLIER if w > MAX_MULTIPLIER
        other_state[k] = w
        other_state["_count_#{k}"] = v
      end
      save!
    end

    def weight_for_key(k)
      (@weight_for_key ||= {})[k] ||= other_state[k.to_s].to_f
    end

    def count_for_key(k)
      other_state["_count_#{k}"]
    end

    # overridable mechanism for converting a multinomial attribute into a binary one
    def group(v)
      v if v.present?
    end

    def score(c1, c2)
      return unless (s = similarity(c1, c2))

      sc = weight * (s - mean) / standard_deviation
      if s.zero?
        sc * weight_for_key(value(c1))
      else
        sc
      end
    end

    def value(c)
      group c.send(field)
    end

    def similarity(c1, c2)
      return unless field

      v1 = value(c1)
      v2 = value(c2)
      return unless v1 && v2

      if v1 == v2
        0
      else
        1
      end
    end
  end
end
