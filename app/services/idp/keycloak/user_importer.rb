###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'json'

module Idp
  module Keycloak
    # Temporary migration tooling: builds Keycloak partialImport payloads from
    # legacy Devise/warehouse User records (password hashes, TOTP secrets, group
    # membership) and pushes them through KeycloakService#partial_import. The one
    # place that couples Keycloak provisioning to the warehouse User model.
    #
    # Delete this class, and KeycloakService#partial_import, once all account
    # data has been migrated.
    class UserImporter
      # The Keycloak groups the import references, keyed by the access they map to;
      # ensured to exist before import.
      GROUPS = {
        warehouse: 'warehouse-users',
        hmis: 'hmis-users',
      }.freeze

      # Users to migrate: confirmed and active.
      #
      # confirmed_at also gates out invited-but-not-accepted users: :invitable
      # and :confirmable run together, so confirmed_at is only set once an
      # invitation is accepted. Those users have no credential to carry and are
      # provisioned on first JWT login instead — keep this filter.
      #
      # @param since [Time, nil] limit to users changed since this time, for a
      #   cheap re-run that catches edits made during migration; nil exports all.
      def self.migration_scope(since: nil)
        scope = User.where.not(confirmed_at: nil).where(active: true)
        scope = scope.where(updated_at: since..) if since
        scope
      end

      # @param service [Idp::KeycloakService] transport used to reach the Admin API
      def initialize(service:)
        @service = service
      end

      # Build one user's Keycloak partialImport entry, with password and TOTP
      # credentials in Keycloak's format.
      def build_import_user_data(user)
        {
          username: user.email,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          enabled: true,
          emailVerified: user.confirmed_at.present?,
          groups: keycloak_groups_for(user),
          credentials: [
            build_password_data(user),
            build_otp_credential(user),
          ].compact,
        }
      end

      # Bulk import users via the partialImport API.
      # @param policy [String] conflict policy: 'OVERWRITE', 'SKIP', or 'FAIL'.
      #   Defaults to OVERWRITE at the caller so re-runs carry over edits.
      def bulk_import_users(users, policy:)
        response = service.partial_import(import_payload(users, policy: policy))
        body = parse_body(response)

        if (200..299).cover?(response.code.to_i)
          # Keycloak reports what it actually did; an attempted count would
          # overstate re-runs where most users are skipped or unchanged.
          {
            success: true,
            attempted: users.size,
            added: body['added'],
            skipped: body['skipped'],
            overwritten: body['overwritten'],
            response: body,
          }
        else
          {
            success: false,
            error: "Import failed (#{response.code}): #{error_message_from(response)}",
            failed_count: users.size,
          }
        end
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, SocketError => e
        {
          success: false,
          error: e.message,
          failed_count: users.size,
        }
      end

      # Idempotently ensure the groups the import references exist, so partialImport
      # can resolve each user's group paths. Safe to re-run. Raises Idp::ServiceError
      # if a group can neither be found nor created.
      # @return [Hash] { created: [String], existing: [String] }
      def ensure_groups!
        result = { created: [], existing: [] }
        GROUPS.each_value do |name|
          case service.ensure_group(name)
          when :created then result[:created] << name
          when :existing then result[:existing] << name
          end
        end
        result
      end

      # Build the partialImport JSON structure without making an API call.
      def export_users_to_import_format(users, policy:, progress: nil)
        import_payload(users, policy: policy, progress: progress)
      end

      # Import users from a JSON file via the partialImport API.
      def import_from_file(file_path)
        raise Idp::ServiceError, "File not found: #{file_path}" unless File.exist?(file_path)

        import_data = JSON.parse(File.read(file_path))
        response = service.partial_import(import_data)

        return { success: true, response: parse_body(response) } if (200..299).cover?(response.code.to_i)

        raise Idp::ServiceError.new(
          "Import failed (#{response.code}): #{error_message_from(response)}",
          idp_name: service.idp_name,
          operation: :import_from_file,
        )
      end

      private

      attr_reader :service

      def import_payload(users, policy:, progress: nil)
        data = users.map do |user|
          progress&.increment!
          build_import_user_data(user)
        end
        {
          ifResourceExists: policy,
          users: data,
        }
      end

      def keycloak_groups_for(user)
        return [] if user.system_user?

        groups = []
        groups << "/#{GROUPS[:warehouse]}" if warehouse_user?(user)
        groups << "/#{GROUPS[:hmis]}" if Hmis::UserGroupMember.exists?(user_id: user.id)
        groups
      end

      # A user belongs in /warehouse-users only if they have actual warehouse
      # access. ACL users express that as warehouse UserGroup membership; legacy
      # users express it as a legacy role (UserRole) or membership in a general
      # (shared) access group. The per-user personal access group every user
      # gets on save (AccessGroup#user_id == their own id) grants nothing on its
      # own, so it is excluded via the `general` scope. HMIS-only accounts have
      # none of these — their access lives entirely in the Hmis:: namespace —
      # and are correctly left out.
      def warehouse_user?(user)
        return user.user_group_members.exists? if user.using_acls?

        user.user_roles.exists? || user.access_groups.general.exists?
      end

      # Build a Keycloak password credential from the user's bcrypt hash.
      def build_password_data(user)
        return nil unless user.encrypted_password.present?

        {
          type: 'password',
          secretData: { value: user.encrypted_password, salt: '' }.to_json,
          credentialData: { hashIterations: bcrypt_cost(user.encrypted_password), algorithm: 'bcrypt' }.to_json,
          temporary: false,
        }
      end

      # bcrypt embeds its cost factor in the hash ($2a$<cost>$<salt+digest>), and
      # Keycloak's credentialData must report that same cost. A hardcoded value
      # would misreport credentials hashed at a different cost (Devise here uses
      # 12) and prompt Keycloak to flag them for needless rehashing.
      def bcrypt_cost(encrypted_password)
        encrypted_password.split('$')[2].to_i
      end

      # Build a Keycloak TOTP credential from the user's decrypted OTP secret.
      # The TOTP secret migrates but otp_backup_codes do not — Keycloak's
      # recovery-code format has no clean partialImport mapping. Affected users
      # fall back to their authenticator app or an admin 2FA reset.
      def build_otp_credential(user)
        return nil unless user.otp_required_for_login?

        begin
          # user.otp_secret bridges both storage locations: the Rails-encrypted otp_secret
          # column (devise-two-factor 6.x) and the legacy encrypted_otp_secret* columns.
          otp_secret = user.otp_secret
        rescue StandardError => e
          Rails.logger.warn "Failed to decrypt OTP secret for #{user.email}: #{e.message}"
          return nil
        end

        return nil unless otp_secret.present?

        {
          type: 'otp',
          secretData: { value: otp_secret }.to_json,
          # Devise stores the secret as a Base32 string; secretEncoding tells Keycloak to
          # Base32-decode it before use as the HMAC key (otherwise it hashes the raw bytes).
          credentialData: {
            subType: 'totp', digits: 6, counter: 0, period: 30, algorithm: 'HmacSHA1',
            secretEncoding: 'BASE32'
          }.to_json,
        }
      end

      # partialImport returns a JSON body with added/skipped/overwritten counts;
      # tolerate a missing or non-JSON body rather than raising on the 2xx path.
      def parse_body(response)
        JSON.parse(response.body)
      rescue JSON::ParserError, TypeError
        {}
      end

      def error_message_from(response)
        data = JSON.parse(response.body)
        data['errorMessage'] || data['error_description'] || data['error'] || response.body
      rescue StandardError
        response.body
      end
    end
  end
end
