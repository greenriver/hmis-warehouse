###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

###
# This class interacts with the external AHA API to fetch client scores for Coordinated Entry.
# Scores are fetched by MCI Unique ID.
#
# For more details, see internal documentation:
#  https://docs.google.com/document/d/1Gcz9-t_utRcqGV9xCzQvTehjQOCqqPv_5-JY_IhhL4Q/
#
# Example Credential Setup:
# aha_cred = GrdaWarehouse::RemoteCredentials::ApiKey.where(slug: 'ac_hmis_aha').first_or_initialize
# aha_cred.attributes = {
#   username: '',
#   active: true,
#   base_url: 'https://<base url>',
#   authorization_header: 'Bearer <bearer token>',
#   additional_headers: {
#     'token': '<app token>',
#     'role': '<role public id>',
#   }
# }
# aha_cred.save!
#
#
# Investigating logs:
#  HmisExternalApis::ExternalRequestLog.outgoing.url_like("scores").failed.where(requested_at: 3.days.ago..).count
###
module HmisExternalApis::AcHmis
  class Aha
    # Lookup catalyst and reason are optional values; if present on the form, they should be submitted when we make the fetch call.
    # Before submitting, validate against the list of allowed values.
    # (Validate here, instead of in the graphql schema, so we have flexibility to ignore instead of raise when receiving invalid values)
    LOOKUP_CATALYST_ALLOWED_VALUES = [
      'OCS Staff',
      'OCS Admin',
      'Non-OCS Program Admin',
      'DHS Administration',
    ].freeze
    LOOKUP_REASON_ALLOWED_VALUES = [
      'Other',
      'Vacancy Management',
      'Prioritization Request',
      'DHS Housing Integration',
    ].freeze

    SYSTEM_ID = 'ac_hmis_aha'
    # Internal symbol keys map to the generator string returned by the Scores API.
    # Use normalize_generator to match API/request values case-insensitively.
    GENERATORS = {
      aha: 'AHA',
      mh_aha: 'MH-AHA',
      visionlink: 'VisionLink',
    }.freeze
    VALID_SCORES = [-1, *(1..10)].freeze # AHA and MH-AHA can be -1 or 1..10, but not zero.
    CONNECTION_TIMEOUT_SECONDS = Rails.env.staging? ? 15 : 10

    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to AHA')
    # Custom error class for MciUniqueId so the mutation can catch it
    class NoMciUniqueIdError < HmisErrors::ApiError; end

    # Fetches scores from the external Scores API for an HMIS source client, and any
    # linked source clients sharing the same destination client.
    #
    # @param client [Hmis::Hud::Client] HMIS source client (not a destination/warehouse client)
    # @param lookup_catalyst [String, nil] optional catalyst submitted to the API when present on the form
    # @param lookup_reason [Array<String>, nil] optional reasons submitted to the API when present on the form
    # @param requested_generators [Array<Symbol>] `:aha`, `:mh_aha`, and/or `:visionlink` (default: `[:aha]`)
    # @return [Hash] keyed by requested generator, with typed result objects (see build_results)
    #   => { aha: AhaScores::AhaResult(...), mh_aha: AhaScores::MhAhaResult(...), visionlink: AhaScores::VisionLinkResult(...) }
    def fetch_score(client, lookup_catalyst: nil, lookup_reason: nil, requested_generators: [:aha])
      raise ArgumentError, "unsupported generators: #{requested_generators.inspect}" unless requested_generators.all? { |key| GENERATORS.key?(key) }

      # Collect MCI unique IDs for this client and all source clients with the same destination client
      clients = [client, *client.destination_client&.source_clients&.to_a]
      mci_uniq_ids = clients.compact.uniq.filter_map do |c|
        c.ac_hmis_mci_unique_id&.value
      end.uniq.sort

      raise NoMciUniqueIdError if mci_uniq_ids.empty?

      payload = create_payload(mci_uniq_ids, lookup_catalyst, lookup_reason)

      result = conn.post('api/v1/clients/scores/search/', payload).
        then { |r| handle_error(r) }

      # If the API returns "No client found" error, the external system was unable to find the MCI Unique ID.
      # Raise the same error as if the client had no MCI Unique ID, so the mutation/frontend handle it in the same way.
      # Note: this is a hotfix for a bug introduced in release-188. IF we need to differentiate between the two cases,
      # we can add a new error class and adjust end-user messaging.
      raise NoMciUniqueIdError if client_not_found_response?(result)

      data = result.parsed_body&.dig('data')
      raise(Error, "Scores API response missing `data` key. Response body: `#{result.parsed_body}`") unless data

      parsed_by_generator = parse_response_scores(data)
      build_results(parsed_by_generator, requested_generators)
    end

    def self.enabled?
      ::GrdaWarehouse::RemoteCredentials::ApiKey.active.where(slug: SYSTEM_ID).exists?
    end

    private

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredentials::ApiKey.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||= HmisExternalApis::ApiKeyConnection.new(creds, connection_timeout: CONNECTION_TIMEOUT_SECONDS)
    end

    def normalize_generator(raw)
      normalized = raw.to_s.downcase.strip.tr('_', '-')
      GENERATORS.find do |key, label|
        key.to_s.tr('_', '-') == normalized || label.downcase == normalized
      end&.first
    end

    # Walks the API `data` array (one element per matching client) and collects valid parsed
    # scores grouped by generator. Each client may return multiple score entries; sibling MCI IDs
    # may each appear as separate clients. Unknown generators are skipped. Invalid entries are
    # skipped after logging to Sentry (see parse_score_entry). The highest score per generator is
    # chosen later in build_results.
    #
    # Example API shape:
    #   data: [
    #     { 'dw_client_id' => '100000001', 'scores' => [
    #       { 'score' => 7, 'generator' => 'AHA', 'metadata' => { 'alt_aha_flag' => '1' } },
    #       { 'score' => 5, 'generator' => 'MH-AHA', 'metadata' => { ... } },
    #     ]},
    #     { 'dw_client_id' => '100000002', 'scores' => [
    #       { 'score' => 9, 'generator' => 'AHA', 'metadata' => { 'alt_aha_flag' => '0' } },
    #     ]},
    #   ]
    #
    # Example return value:
    #   { aha: [AhaResult(score: 7, ...), AhaResult(score: 9, ...)], mh_aha: [MhAhaResult(score: 5, ...)] }
    def parse_response_scores(data)
      parsed_by_generator = Hash.new { |hash, key| hash[key] = [] }

      data.each do |response_client|
        dw_client_id = Array.wrap(
          response_client.dig('dw_client_id') || response_client.dig('dw_client_id_dw_client_id'),
        ).first

        response_client.dig('scores')&.each do |score_obj|
          generator_key = normalize_generator(score_obj['generator'])
          next unless generator_key

          parsed = parse_score_entry(score_obj, dw_client_id, generator_key)
          parsed_by_generator[generator_key] << parsed if parsed
        end
      end

      parsed_by_generator
    end

    # Parses a single score entry from the API into a typed result for the given generator.
    # Returns nil (without raising) when the entry is invalid; logs the failure to Sentry so
    # other entries and generators can still be returned.
    #
    # Example score_obj (AHA):
    #   { 'score' => 8, 'generator' => 'AHA', 'metadata' => { 'alt_aha_flag' => '0' } }
    #   => AhaScores::AhaResult(score: 8, mci_quality_indicator: 0, dw_client_id: '100000001', generator: 'AHA')
    #
    # Example score_obj (VisionLink):
    #   { 'score' => -999, 'generator' => 'VisionLink', 'metadata' => { 'is_eligible_ra' => false, ... } }
    #   => AhaScores::VisionLinkResult(score: -999, is_eligible_ra: false, ...)
    def parse_score_entry(score_obj, dw_client_id, generator_key)
      case generator_key
      when :aha then parse_aha_entry(score_obj, dw_client_id)
      when :mh_aha then parse_mh_aha_entry(score_obj, dw_client_id)
      when :visionlink then parse_visionlink_entry(score_obj, dw_client_id)
      end
    rescue StandardError => e
      Sentry.capture_message(
        "AHA received invalid #{GENERATORS.fetch(generator_key)} score entry: #{e.message}",
      )
      nil
    end

    # Parses an AHA generator entry. Score must be an integer in [-1, 1..10] (zero invalid).
    # Extracts alt_aha_flag from metadata as mci_quality_indicator.
    #
    # Example:
    #   score_obj: { 'score' => 8, 'generator' => 'AHA', 'metadata' => { 'alt_aha_flag' => '0' } }
    #   dw_client_id: '100000001'
    #   => AhaScores::AhaResult(score: 8, mci_quality_indicator: 0, dw_client_id: '100000001', generator: 'AHA')
    def parse_aha_entry(score_obj, dw_client_id)
      score = parse_standard_score(score_obj.dig('score'))

      AhaScores::AhaResult.new(
        score: score,
        mci_quality_indicator: score_obj.dig('metadata', 'alt_aha_flag')&.to_i,
        dw_client_id: dw_client_id,
        generator: score_obj['generator'],
      )
    end

    # Parses an MH-AHA generator entry. Uses the same score validation as AHA ([-1, 1..10]).
    #
    # Example:
    #   score_obj: { 'score' => 5, 'generator' => 'MH-AHA', 'metadata' => { 'row_id' => '123', 'run_id' => 'aha_abc' } }
    #   dw_client_id: '100000022'
    #   => AhaScores::MhAhaResult(score: 5, dw_client_id: '100000022', generator: 'MH-AHA')
    def parse_mh_aha_entry(score_obj, dw_client_id)
      score = parse_standard_score(score_obj.dig('score'))

      AhaScores::MhAhaResult.new(
        score: score,
        dw_client_id: dw_client_id,
        generator: score_obj['generator'],
      )
    end

    # Parses a VisionLink generator entry. Accepts any numeric score (including -999, which means
    # no score but may still carry eligibility flags). Metadata field types are preserved as returned
    # by the API (booleans stay boolean, numeric flags stay numeric).
    #
    # Example:
    #   score_obj: {
    #     'score' => -999,
    #     'generator' => 'VisionLink',
    #     'metadata' => {
    #       'is_eligible_ra' => false, 'currently_unhoused' => false, 'is_eligible_cc' => true,
    #       'homeless_risk' => 0, 'section_8' => 0, 'city_of_pittsburgh' => 0,
    #       'subsidized_housing' => 0, 'recent_erap_use' => 0,
    #     },
    #   }
    #   dw_client_id: '100000022'
    #   => AhaScores::VisionLinkResult(score: -999, is_eligible_ra: false, is_eligible_cc: true, ...)
    def parse_visionlink_entry(score_obj, dw_client_id)
      score_value = score_obj.dig('score')
      raise ArgumentError, 'Received blank score' if score_value.blank?
      raise ArgumentError, "Received invalid score: #{score_value.inspect}" unless score_value.is_a?(Numeric)

      metadata = score_obj['metadata'] || {}

      AhaScores::VisionLinkResult.new(
        score: score_value,
        dw_client_id: dw_client_id,
        generator: score_obj['generator'],
        is_eligible_ra: metadata['is_eligible_ra'],
        currently_unhoused: metadata['currently_unhoused'],
        is_eligible_cc: metadata['is_eligible_cc'],
        homeless_risk: metadata['homeless_risk'],
        section_8: metadata['section_8'],
        city_of_pittsburgh: metadata['city_of_pittsburgh'],
        subsidized_housing: metadata['subsidized_housing'],
        recent_erap_use: metadata['recent_erap_use'],
      )
    end

    def parse_standard_score(score_value)
      raise ArgumentError, 'Received blank score' if score_value.blank?
      raise ArgumentError, "Received invalid score: #{score_value.inspect}" unless score_value.is_a?(Numeric) && score_value % 1 == 0 && VALID_SCORES.include?(score_value.to_i)

      score_value.to_i
    end

    # Selects the highest-scoring parsed entry per requested generator and returns a hash keyed
    # by generator symbol. Values are typed result objects or nil when that
    # generator was requested but no valid entries were found in the API response.
    #
    # Example return value for requested_generators: [:aha, :mh_aha, :visionlink]
    #   {
    #     aha: AhaScores::AhaResult(score: 9, mci_quality_indicator: 0, dw_client_id: '100000002', generator: 'AHA'),
    #     mh_aha: AhaScores::MhAhaResult(score: 5, dw_client_id: '100000001', generator: 'MH-AHA'),
    #     visionlink: nil,
    #   }
    def build_results(parsed_by_generator, requested_generators)
      # For each requested generator, select the highest score from the parsed entries.
      # Returns a hash of generator keys to the best score result for that generator.
      results = requested_generators.index_with do |generator_key|
        parsed_by_generator[generator_key].compact.max_by(&:score)
      end

      results
    end

    def create_payload(mci_uniq_ids, lookup_catalyst, lookup_reason)
      payload = {}

      if mci_uniq_ids.size > 1
        payload[:dw_client_id__dw_client_id__overlap] = mci_uniq_ids.join(',')
      else
        payload[:dw_client_id__dw_client_id__includes] = mci_uniq_ids.first
      end

      # For lookup catalyst and lookup reasons, don't send unknown values to the external API,
      # but log to Sentry if we receive unexpected values so we don't silently skip them.
      if lookup_catalyst.present?
        if LOOKUP_CATALYST_ALLOWED_VALUES.include?(lookup_catalyst)
          payload[:lookup_catalyst] = lookup_catalyst
        else
          Sentry.capture_message("AHA received unexpected lookup catalyst: #{lookup_catalyst}")
        end
      end

      if lookup_reason.present?
        valid_reasons, unknown_reasons = lookup_reason.partition { |r| LOOKUP_REASON_ALLOWED_VALUES.include?(r) }

        payload[:lookup_reason] = valid_reasons if valid_reasons.any?

        Sentry.capture_message("AHA received unexpected lookup reason(s): #{unknown_reasons.join(', ')}") if unknown_reasons.any?
      end

      payload
    end

    def handle_error(result)
      if result.error
        Rails.logger.error "AHA API Error: #{result.error}"
        raise(Error, result.error)
      end

      # Check if HTTP status indicates success (200-299 range)
      return result if http_status_successful?(result.http_status)

      raise(Error, "AHA HTTP error: Received non-200 HTTP status: #{result.http_status}")
    end

    def http_status_successful?(status)
      status.in?(200..299)
    end

    def client_not_found_response?(result)
      result.parsed_body&.dig('message')&.match?(/no client found/i)
    end
  end
end
