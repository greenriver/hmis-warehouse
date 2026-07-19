###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'progress_bar'

module Idp
  module Keycloak
    class AuthenticationSourceBackfill
      Result = Struct.new(:total, :linked, :already, :missing, keyword_init: true) do
        def summary
          summary_lines.join("\n")
        end

        def summary_lines
          [
            'Backfill complete!',
            "  In scope:          #{total}",
            "  Newly linked:      #{linked}",
            "  Already linked:    #{already}",
            "  Missing from KC:   #{missing}",
          ]
        end
      end

      attr_reader :service, :connector_id

      def self.call(...)
        new(...).call
      end

      # @param service [Idp::Service] transport whose #user_scope drives the set to
      #   link and whose #each_user builds the email => id map.
      # @param connector_id [String] the JWT routing key rows are keyed on, so a
      #   backfilled row matches what first-login writes from the token. Held by
      #   the caller (the ServiceConfig), passed in rather than resolved here.
      # @param progress [Boolean] show a ProgressBar (interactive rake runs only).
      def initialize(service:, connector_id:, progress: false)
        @service = service
        @connector_id = connector_id
        @progress = build_progress_bar if progress
      end

      # @return [Result]
      def call
        ids_by_email = build_email_id_map

        users = service.user_scope
        total = users.count
        linked = 0
        already = 0
        missing = 0

        # A fresh deployment, or a re-run before any user is confirmed and active.
        if total.zero?
          log 'No confirmed, active users in scope; nothing to backfill.'
          return Result.new(total: 0, linked: 0, already: 0, missing: 0)
        end

        log "Backfilling authentication sources for #{total} users..."
        users.find_each do |user|
          @progress&.increment!

          id = ids_by_email[user.email.downcase]
          if id.blank?
            # In scope locally but absent from Keycloak (e.g. skipped during
            # import). Do not write a source pointing at a guessed id.
            missing += 1
            log "  SKIP (not in Keycloak): #{user.email}"
            next
          end

          attrs = { connector_id: connector_id, connector_user_id: id }
          if user.user_authentication_sources.where(attrs).exists?
            already += 1
            next
          end

          begin
            # Mirror Idp::UserProvisioner#ensure_authentication_source exactly
            # (guard -> create! -> rescue), NOT find_or_create_by: the partial
            # unique index turns a lost race against a concurrent first-login into
            # RecordNotUnique. Leave last_connector_id nil — primary_idp falls
            # through to this row's connector_id, and the real first login sets
            # last_connector_id itself.
            user.user_authentication_sources.create!(attrs)
            linked += 1
          rescue ActiveRecord::RecordNotUnique
            # A concurrent first-login created the row; nothing to do.
            already += 1
          end
        end

        Result.new(total: total, linked: linked, already: already, missing: missing)
      end

      private

      def build_progress_bar
        total = service.user_scope.count
        ProgressBar.new(total, :counter, :bar, :percentage, :eta) if total.positive?
      end

      def log(msg)
        Rails.logger.info("#{self.class.name}: #{msg}")
      end

      # One email => id map, keyed on downcased email: the importer writes
      # user.email verbatim while Keycloak stores/matches email lowercased and
      # payload_email downcases too — a mixed-case warehouse email would otherwise
      # miss. A duplicate downcased email in Keycloak should be impossible (unique
      # usernames/emails), so treat it as a data problem rather than overwrite.
      def build_email_id_map
        log 'Building Keycloak email => id map...'
        ids_by_email = {}
        service.each_user do |props|
          email = props[:email].presence&.downcase
          next if email.blank?

          if ids_by_email.key?(email)
            raise Idp::ServiceError.new(
              "Duplicate Keycloak users for email #{email}",
              idp_name: service.idp_name,
              operation: :backfill_authentication_sources,
            )
          end

          ids_by_email[email] = props[:id]
        end
        log "  #{ids_by_email.size} Keycloak users"
        ids_by_email
      end
    end
  end
end
