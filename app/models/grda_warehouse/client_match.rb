module GrdaWarehouse
  class ClientMatch < GrdaWarehouseBase
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :updated_by, class_name: 'User'
    serialize :score_details, Hash
    validates :status, inclusion: {in: ['candidate', 'accepted', 'rejected', 'processed_sources']}

    def self.create_candidates!(client, threshold:, metrics:)
      relavent_fields = ([:id, :DateUpdated]+metrics.map(&:field)).uniq.map(&:to_s)
      data = SimilarityMetric.pairwise_candidates(client, threshold: threshold, metrics: metrics)
      candidates = data.flat_map do |dest, srcs|
        srcs.map do |src, scoring|
          ovarall_score = scoring[:score]
          metrics = scoring[:metrics_with_scores].map do |m, score_on_metric|
            {
              metric_id: m.id,
              type: m.type,
              weight: m.weight,
              field: m.field,
              score: score_on_metric,
              updated_at: m.updated_at,
            }
          end

          create! do |m|
            m.status = 'candidate'
            m.destination_client_id = dest.id
            m.source_client_id = src.id
            m.score = ovarall_score
            m.score_details = {
              threshold: threshold,
              destination_client: dest.attributes.slice(*relavent_fields),
              source_client: src.attributes.slice(*relavent_fields),
              metrics_with_scores: metrics,
            }
          end
        end
      end
    end

    def accepted?
      self.status == 'accepted'
    end

    def rejected?
      self.status == 'rejected'
    end

    def candidate?
      self.status == 'candidate'
    end


    # return an indication of the field(s) (could be an array)
    # contribution to the overall score
    # expressed as a weighted average of the z-scores for those fields only
    def score_contribution(fields)
      fields = Array(fields).map(&:to_s)
      weight_sum = 0.0;
      score_sum = 0.0;
      score_details['metrics_with_scores'].each do |detail|
        if detail['field'].in? fields
          weight_sum += detail['weight']
          score_sum += detail['score']
        end
      end
      return nil if weight_sum.zero?

      score_sum/weight_sum
    end
  end
end
