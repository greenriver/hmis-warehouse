###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  # metric of similarity for properties with a fixed number of distinct values
  class Multinomial < Field

    DESCRIPTION = <<~eos
      _{{{human_name}}}_ measures similarity of individuals with respect to
      a property that can take one of several distinct values.
    eos

    # the maximum additional weight given to similar items
    MAX_MULTIPLIER = 3.0   # picked by intuition rather than experiment

    def max_multiplier
      self.class::MAX_MULTIPLIER
    end

    # Determine the frequencies of the various possible values of this multinomial field.
    # This uses *all* available data, not just a sample, since this is cheap.
    # This information will then be used to weight similarity measures.
    def prepare!
      if GrdaWarehouse::Hud::Client.column_names.include?(field.to_s)
        counts = GrdaWarehouse::Hud::Client.source.group(field).count
        # merge the counts of equivalent values
        grouped = Hash.new(0).tap do |grouped|
          counts.each do |k, v|
            if (k = group(k))
              grouped[k] += v
            end
          end
        end
        total = grouped.values.sum
        other_state['_total'] = total
        # convert these counts into weights
        # the idea here is that similarity in more unusual values of the field is more significant
        grouped.each do |k,v|
          w = [total / v.to_f, MAX_MULTIPLIER].max
          other_state[k] = w
          other_state["_count_#{k}"] = v
        end
        save!
      end
    end

    def weight_for_key(k)
      ( @weight_for_key ||= {} )[k] ||= other_state[k.to_s].to_f
    end

    def count_for_key(k)
      other_state["_count_#{k}"]
    end

    # overridable mechanism for converting a multinomial attribute into a binary one
    # or otherwise treating different values of the field as equivalent
    def group(v)
      v if v.present?
    end

    def score(c1, c2)
      if s = similarity( c1, c2 )
        sc = weight * ( s - mean ) / standard_deviation
        if s == 0
          sc * weight_for_key(value(c1))
        else
          sc
        end
      end
    end

    # the value of the field, modulo grouping, for client c
    def value(c)
      group c.send(field)
    end

    # if the two clients both have a value for the field, they have some similarity
    # if they have the same value for the field, it is 0, otherwise, 1
    def similarity(c1, c2)
      if field
        v1, v2 = value(c1), value(c2)
        if v1 && v2
          if v1 == v2
            0
          else
            1
          end
        end
      end
    end

  end
end
