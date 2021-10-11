###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientMatch < GrdaWarehouseBase
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true
    serialize :score_details, Hash
    validates :status, inclusion: {in: ['candidate', 'accepted', 'rejected', 'processed_sources']}

    # To keep track so we don't re-run create_candidates for a given destination client
    scope :processed, -> do
      where(status: 'processed_sources')
    end

    scope :candidate, -> do
      where(status: 'candidate')
    end

    scope :accepted, -> do
      where(status: 'accepted')
    end

    scope :rejected, -> do
      where(status: 'rejected')
    end

    scope :processed_or_candidate, -> do
      where(status: ['processed_sources', 'candidate'])
    end

    scope :within_auto_accept_threshold, -> do
      threshold = auto_accept_threshold
      return none unless auto_matching_enabled? && threshold.present?

      # Scores are negative, thresholds positive
      # Scores range down into the -3s so -10 should be safe
      candidate.where(score: [-10..-threshold])
    end

    scope :within_auto_reject_threshold, -> do
      threshold = auto_reject_threshold
      return none unless auto_matching_enabled? && threshold.present?

      # Scores are negative, thresholds positive
      candidate.where(score: [-threshold..0])
    end

    def self.auto_process!
      # Don't do anything if we don't have any destination clients
      return unless GrdaWarehouse::Hud::Client.destination.count.positive?

      # Initialize before running if we've never run before
      SimilarityMetric::Initializer.new.run! if GrdaWarehouse::ClientMatch.count.zero?
      within_auto_accept_threshold.joins(:source_client, :destination_client).
        find_each(&:accept!)
      within_auto_reject_threshold.joins(:source_client, :destination_client).
        find_each(&:reject!)
    end

    def self.auto_matching_enabled?
      GrdaWarehouse::Config.get(:auto_de_duplication_enabled) == true
    end

    def self.auto_accept_threshold
      threshold = GrdaWarehouse::Config.get(:auto_de_duplication_accept_threshold)
      return nil if threshold.blank? || threshold.zero?

      threshold
    end

    def self.auto_reject_threshold
      threshold = GrdaWarehouse::Config.get(:auto_de_duplication_reject_threshold)
      return nil if threshold.blank? || threshold.zero?

      threshold
    end

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

    def self.score_distribution(match_type: :all)
      scope = case match_type
      when :all
        all
      when :accepted
        accepted
      when :rejected
        rejected
      when :processed_or_candidate
        processed_or_candidate
      end

      scope.
        where.not(score: nil).
        group(Arel.sql('ROUND(cast(score as numeric), 1)')).
        count(1).
        transform_keys(&:abs)
    end

    def self.for_chart(match_type: :all)
      dist = score_distribution(match_type: match_type)
      x = [:x] + dist.keys
      y = ['Match Count'] + dist.values
      {
        columns: [
          x,
          y,
        ],
      }
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
      fields = Array(fields).map(&:to_sym)
      weight_sum = 0.0;
      score_sum = 0.0;
      if score_details.with_indifferent_access[:metrics_with_scores].present?
        score_details.with_indifferent_access[:metrics_with_scores].each do |detail|
          if detail.with_indifferent_access[:field].to_sym.in?(fields)
            weight_sum += detail.with_indifferent_access[:weight]
            score_sum += detail.with_indifferent_access[:score]
          end
        end
      end
      return nil if weight_sum.zero?

      score_sum/weight_sum
    end

    def accept!(user: nil)
      flag_as(user: user, status: 'accepted')
      return unless destination_client && source_client

      dst = destination_client.destination_client
      src = source_client
      dst.merge_from(src, reviewed_by: user, reviewed_at: Time.current, client_match_id: id)
      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
    end

    def flag_as(user: nil, status:)
      user ||= User.setup_system_user
      update(
        updated_by_id: user.id,
        status: status,
      )
    end

    def reject!(user: nil)
      flag_as(user: user, status: 'rejected')
      save!
    end
  end
end
