###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric

  module_function

  # for a given client and list of candidates, return a map from those candidates to their scores (for scores below some threshold)
  def score(client, others, metrics: Base.usable.all.reject(&:bogus?), threshold: 0, just_score: true)
    return {} if metrics.empty? || others.empty?

    others.map do |other|
      s = single_score client, other, metrics: metrics, just_score: just_score
      sc = just_score ? s : s[:score]
      if sc < threshold
        [ other, s ]
      end
    end.compact.to_h
  end

  # for a particular candidate return a map from candidate mergees to scores
  #    client     -- target destination client for which merge candidates are sought
  #    limit      -- number of coarsely selected candidates to re-rank sought per source client of target
  #    threshold  -- score above which candidates will be rejected; -1 means roughly one standard deviation more similar than typical for randomly chosen inviduals
  #    metrics    -- list of similarity metrics to use
  #    minimum    -- minimum number of candidates to return -- this determines application of use_zero_crossing
  #    just_score -- we are only interested in the final score, not the elements it was composed from; if false, you get back a hash rather than a float
  #    use_zero_crossing -- use second derivative of score crossing or touching 0 as an inflection point below which candidates are dropped
  def candidates(
    client,
    limit:             500,
    threshold:         -1,
    metrics:           SimilarityMetric::Base.usable.all.reject(&:bogus?),
    minimum:           3,
    just_score:        true,
    use_zero_crossing: true
  )
    sources = client.destination? ? client.source_clients : [client]
    excludables = sources.map(&:id)
    score_map = sources.map do |client|
      others = client.merge_candidates.where.not( id: excludables ).limit(limit)
      score( client, others, metrics: metrics, threshold: threshold, just_score: false )
    end.reduce({}){ |s1, s2| merge_scores s1, s2, just_score: false }
    score_map = score_map.map do |client, map|
      value = rescore_amalgam map
      unless just_score
        map[:score] = value
        value = map
      end
      [ client, value ]
    end.to_h
    score_map = cull_by_zero_crossing( score_map, just_score ) if use_zero_crossing && score_map.size > minimum
    score_map
  end

  # like candidates but it returns both a map from merge candideates to scores
  # and a map from source clients to maps from merge candidates to scores or score hashes, depending on the value of just_score
  #
  #  returns:
  #    { source_clients => { merge_candidates => { score: float, metrics_with_scores: { metrics => scores } } } }
  def pairwise_candidates(
    client,
    limit:             500,
    threshold:         -1,
    metrics:           SimilarityMetric::Base.usable.all.reject(&:bogus?),
    minimum:           3,
    use_zero_crossing: true
  )
    # first we get the best merge candidates for each source client
    sources              = client.destination? ? client.source_clients : [client]
    excludables          = sources.map(&:id)
    scores_per_candidate = {}
    sources_to_matches = sources.map do |client|
      # all candidates
      others = client.merge_candidates.where.not( id: excludables ).limit(limit)
      # map from candidates to score/metric hashes
      matches = score( client, others, metrics: metrics, threshold: threshold, just_score: false )
      # cull by threshold
      matches.select!{ |_,h| h[:score] <= threshold }
      # cull by zero crossing (edge of score plateau) if appropriate
      if use_zero_crossing && matches.size > minimum
        matches = cull_by_zero_crossing matches, false
      end
      # keep track of scores per candidate so we only show the best pairwise matches
      matches.each do |candidate, hash|
        ( scores_per_candidate[candidate] ||= [] ) << hash[:score]
      end
      [ client, matches ]
    end.to_h
    # cull pairs down to the highest (lowest) scorers
    sources_to_matches.values.each do |candidates_to_scores|
      candidates_to_scores.select! do |c, scores|
        scores[:score] <= scores_per_candidate[c].min
      end
    end
    sources_to_matches
  end

  # cull a score map to just those client-score pairs on an initial "score plateau"
  def cull_by_zero_crossing( score_map, just_score=true )
    crossing, position, velocity, acceleration, any_acceleration = nil, nil, nil, nil, false
    score_map.values.sort_by{ |v| just_score ? v : v[:score] }.each do |x|
      x = x[:score] unless just_score
      if position
        v = x - position
        if velocity
          a = v - velocity
          if any_acceleration && ( ( acceleration < 0 ) ^ ( a < 0 ) )
            crossing = x
            break
          end
          acceleration = a
          any_acceleration ||= acceleration != 0
        end
        velocity = v
      end
      position = x
    end
    if crossing
      score_map.select do |_,score|
        score = score[:score] unless just_score
        score <= crossing
      end
    else
      score_map
    end
  end

  # take a merged set of score maps and calculate a new score using the best weight for each metric
  def rescore_amalgam(score_map)
    score_map = score_map[:metrics_with_scores]
    return Float::MAX if score_map.empty?
    score_map.map{ |k,v| k.weight * v }.sum / score_map.size
  end

  # calculate score for a pair of individuals
  def single_score(c1, c2, metrics: Base.usable.all.reject(&:bogus?), just_score: true)
    weights = []
    scores = metrics.map do |m|
      if s = m.score( c1, c2 )
        weights << m
        s
      end
    end.compact
    s = if scores.any?
      scores.sum / weights.map(&:weight).sum
    else
      Float::INFINITY
    end
    if just_score
      s
    else
      {
        score: s,
        metrics_with_scores: weights.zip(scores).to_h
      }
    end
  end

  # merge two sets of client -> score maps, keeping higher similarity scores when there are collisions
  # higher similarity means lower (negative) score
  def merge_scores(scores1, scores2, just_score: true)
    ( scores1.keys + scores2.keys ).uniq.map do |c|
      v1, v2 = scores1[c], scores2[c]
      v = if v1 && v2
        s1, s2 = [ v1, v2 ].map{ |v| just_score ? v : v[:score] }
        s1 < s2 ? v1 : v2
      else
        v1 || v2
      end
      [ c, v ]
    end.to_h
  end

  # for a reference client, rank the others by their similarity to it, dropping any whose
  # similarity is unmeasurable or which falls below the optional threshold
  def rank(client, others, threshold = 0)
    metrics = Base.usable.all.reject(&:bogus?)
    return others if metrics.empty?

    similarity_scores_for_others = score( client, others, metrics: metrics, threshold: threshold )
    similarity_scores_for_others.keys.sort_by{ |c| similarity_scores_for_others[c] }
  end

end
