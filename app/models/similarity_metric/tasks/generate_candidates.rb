module SimilarityMetric::Tasks
  class GenerateCandidates
   def initialize batch_size:10000, threshold:-1.45, run_length:240
      @opts = {batch_size: batch_size, threshold: threshold, run_length: run_length}
    end

    def run!
      Rails.logger.info "Generating some match candidates: #{@opts.to_json}..."
      start_time = Time.now
      metrics = SimilarityMetric::Base.usable.all.reject(&:bogus?)
      clients = GrdaWarehouse::Hud::Client
      matches = GrdaWarehouse::ClientMatch
      ct = clients.arel_table
      mt = matches.arel_table
      scope = clients.
        destination.
        where( matches.where( mt[:destination_client_id].eq ct[:id] ).exists.not ).
        preload(:source_clients).
        order( id: :desc ).
        limit(@opts[:batch_size])

      scope.each do |dest|
        if Time.now > (start_time + @opts[:run_length].to_i.minutes)
          Rails.logger.info "Ending after #{@opts[:run_length]} minutes"
          break
        end
        Rails.logger.info "Checking #{dest.id}..."
        candidates = matches.create_candidates!(dest, threshold: @opts[:threshold], metrics: metrics)
        match = matches.create! do |m|
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