###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric::Tasks
  class GenerateCandidates
   def initialize batch_size:10000, threshold:-1.45, run_length:240
      @opts = {batch_size: batch_size, threshold: threshold, run_length: run_length}
    end

    def run!
      Rails.logger.info "Generating some match candidates: #{@opts.to_json.html_safe}..."
      start_time = Time.now
      metrics = SimilarityMetric::Base.usable.all.reject(&:bogus?)
      clients_source = GrdaWarehouse::Hud::Client
      matches_source = GrdaWarehouse::ClientMatch
      ct = clients_source.arel_table
      mt = matches_source.arel_table
      # Find clients who don't have a match in the matches table
      scope = clients_source.
        destination.
        where( matches_source.where( mt[:destination_client_id].eq ct[:id] ).arel.exists.not ).
        preload(:source_clients).
        order( id: :desc ).
        limit(@opts[:batch_size])

      scope.each do |dest|
        if Time.now > (start_time + @opts[:run_length].to_i.minutes)
          Rails.logger.info "Ending after #{@opts[:run_length]} minutes"
          break
        end
        Rails.logger.info "Checking #{dest.id}..."
        candidates = matches_source.create_candidates!(dest, threshold: @opts[:threshold], metrics: metrics)
        match = matches_source.create! do |m|
          m.destination_client_id = dest.id
          m.source_client_id = dest.id
          m.status = 'processed_sources'
        end
        if candidates.size == 0
          Rails.logger.info "...none found\n"
        end
        candidates.each do |match|
          Rails.logger.info "...added #{match.source_client_id} #{match.destination_client_id} #{match.score}....\n"
        end
      end
    end
  end
end
