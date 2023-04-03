###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientMatch < GrdaWarehouseBase
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :updated_by, class_name: 'User', optional: true
    serialize :score_details, Hash
    validates :status, inclusion: { in: ['candidate', 'accepted', 'rejected', 'processed_sources'] }

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

    # Occassionally client data changes that updates clients in such
    # a way that they should be caught by identify duplicates
    # Client.merge_from should cleanup the matches, but sometimes
    # doesn't.  This method loops over the existing un-processed matches
    # and accepts any where 2 of 3 of name, SSN, and DOB are exact matches.
    # In addition, if either the source or destination client no longer
    # exists, we'll delete the match
    def self.accept_exact_matches!
      candidate.
        find_each do |match|
          sc = match.source_client
          dc = match.destination_client
          # next puts("match.destroy  #{match.id}") if sc.blank? || dc.blank?
          next match.destroy if sc.blank? || dc.blank?

          ssns_match = ::HudUtility.valid_social?(sc.SSN) && ::HudUtility.valid_social?(dc.SSN) && sc.SSN == dc.SSN
          dobs_match = sc.DOB.present? && dc.DOB.present? && sc.DOB == dc.DOB
          # next puts("ssn: match.accept! #{match.id}") if ssns_match && dobs_match
          next match.accept!(run_service_history_add: false) if ssns_match && dobs_match
          # If we are missing any part of a name, just ignore this
          next if sc.FirstName.blank? || sc.LastName.blank? || dc.FirstName.blank? || dc.LastName.blank?

          names_match = sc.FirstName == dc.FirstName && sc.LastName == dc.LastName
          # puts("name: match.accept!  #{match.id}") if [ssns_match, dobs_match, names_match].count(true) > 1
          match.accept!(run_service_history_add: false) if [ssns_match, dobs_match, names_match].count(true) > 1
        end
      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
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
      relevant_fields = ([:id, :DateUpdated] + metrics.map(&:field)).uniq.map(&:to_s)
      data = SimilarityMetric.pairwise_candidates(client, threshold: threshold, metrics: metrics)
      data.flat_map do |dest, srcs|
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
              destination_client: dest.attributes.slice(*relevant_fields),
              source_client: src.attributes.slice(*relevant_fields),
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
      status == 'accepted'
    end

    def rejected?
      status == 'rejected'
    end

    def candidate?
      status == 'candidate'
    end

    # return an indication of the field(s) (could be an array)
    # contribution to the overall score
    # expressed as a weighted average of the z-scores for those fields only
    def score_contribution(fields)
      fields = Array(fields).map(&:to_sym)
      weight_sum = 0.0
      score_sum = 0.0
      if score_details.with_indifferent_access[:metrics_with_scores].present?
        score_details.with_indifferent_access[:metrics_with_scores].each do |detail|
          if detail.with_indifferent_access[:field].to_sym.in?(fields)
            weight_sum += detail.with_indifferent_access[:weight]
            score_sum += detail.with_indifferent_access[:score]
          end
        end
      end
      return nil if weight_sum.zero?

      score_sum / weight_sum
    end

    def accept!(user: User.system_user, run_service_history_add: true)
      flagged = flag_as(user: user, status: 'accepted')
      return unless flagged && destination_client && source_client

      dst = destination_client.destination_client
      src = source_client
      dst.merge_from(src, reviewed_by: user, reviewed_at: Time.current, client_match_id: id)
      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run! if run_service_history_add
    end

    def flag_as(user: User.system_user, status:)
      update(
        updated_by_id: user.id,
        status: status,
      )
      return true
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotFound
      false
    end

    def reject!(user: nil)
      flag_as(user: user, status: 'rejected')
      save!
    end
  end
end
