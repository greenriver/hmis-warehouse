###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'json'

module Idp
  module Keycloak
    # TEMPORARY migration tooling.
    #
    # Builds Keycloak partialImport payloads from the legacy Devise/warehouse
    # User records (password hashes, TOTP secrets, group membership) and pushes
    # them through Idp::KeycloakService#partial_import. This is the one place
    # that couples Keycloak provisioning to the warehouse User model; the live
    # KeycloakService deliberately knows nothing about it.
    #
    # Delete this class (and KeycloakService#partial_import) once all Devise
    # account data has been migrated into Keycloak.
    class UserImporter
      # The set of warehouse users this tooling migrates: confirmed + active.
      #
      # The `confirmed_at` filter is doing double duty here. The warehouse runs
      # Devise :invitable AND :confirmable together, so *accepting* an invitation
      # is what sets `confirmed_at` — an invited-but-not-accepted user has
      # `confirmed_at: nil` and is excluded by `where.not(confirmed_at: nil)`.
      # That is intentional: such users have no real credential to migrate and
      # are provisioned the normal way (JWT first-login) after the flip. Don't
      # drop this filter thinking it only means "real account".
      #
      # `active: true` is the proven minimal set, not an access boundary —
      # post-flip the IdP gates access, not `users.active`. No `enabled:` mapping.
      #
      # @param since [Time, nil] when present, a delta export — only users whose
      #   `updated_at` is newer (so the migration can be re-run cheaply as the
      #   last step before the flip). Pass nil for the full base population.
      def self.migration_scope(since:)
        scope = User.where.not(confirmed_at: nil).where(active: true)
        scope = scope.where('users.updated_at > ?', since) if since
        scope
      end

      # @param service [Idp::KeycloakService] transport used to reach the Admin API
      def initialize(service:)
        @service = service
      end

      # Build user data for Keycloak partialImport, including password and TOTP
      # credentials in Keycloak's credential format.
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
      # @param policy [String] conflict policy: 'SKIP', 'OVERWRITE', or 'FAIL'
      def bulk_import_users(users, policy: 'SKIP')
        import_data = {
          ifResourceExists: policy,
          users: users.map { |user| build_import_user_data(user) },
        }

        response = service.partial_import(import_data)

        case response.code.to_i
        when 200..299
          {
            success: true,
            imported_count: users.size,
            response: JSON.parse(response.body),
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

      # Build the partialImport JSON structure without making an API call.
      def export_users_to_import_format(users)
        {
          ifResourceExists: 'SKIP',
          users: users.map { |user| build_import_user_data(user) },
        }
      end

      # Import users from a JSON file via the partialImport API.
      def import_from_file(file_path)
        raise Idp::ServiceError, "File not found: #{file_path}" unless File.exist?(file_path)

        import_data = JSON.parse(File.read(file_path))

        response = service.partial_import(import_data)

        case response.code.to_i
        when 200..299
          {
            success: true,
            response: JSON.parse(response.body),
          }
        else
          raise Idp::ServiceError.new(
            "Import failed (#{response.code}): #{error_message_from(response)}",
            idp_name: service.idp_name,
            operation: :import_from_file,
          )
        end
      end

      private

      attr_reader :service

      def keycloak_groups_for(user)
        return [] if user.system_user?

        groups = []
        acl_user_without_groups = user.using_acls? && !user.user_group_members.exists?
        groups << '/warehouse-users' unless acl_user_without_groups
        groups << '/hmis-users' if Hmis::UserGroupMember.exists?(user_id: user.id)
        groups
      end

      # Build a Keycloak password credential from the user's bcrypt hash.
      def build_password_data(user)
        return nil unless user.encrypted_password.present?

        {
          type: 'password',
          secretData: { value: user.encrypted_password, salt: '' }.to_json,
          credentialData: { hashIterations: 10, algorithm: 'bcrypt' }.to_json,
          temporary: false,
        }
      end

      # Build a Keycloak TOTP credential from the user's decrypted OTP secret.
      #
      # Migrates the TOTP secret only — NOT the user's `otp_backup_codes`.
      # Keycloak's recovery-code format differs and there is no clean
      # partialImport mapping, so backup codes are intentionally dropped. A user
      # who relied on them at first post-cutover login must use their
      # authenticator app, or have an admin reset 2FA in Keycloak. See
      # docs/developer/keycloak-idp.md.
      def build_otp_credential(user)
        return nil unless user.encrypted_otp_secret.present? && user.otp_required_for_login?

        begin
          otp_secret = user.otp_secret
        rescue StandardError => e
          Rails.logger.warn "Failed to decrypt OTP secret for #{user.email}: #{e.message}"
          return nil
        end

        return nil unless otp_secret

        {
          type: 'otp',
          secretData: { value: otp_secret }.to_json,
          # secretEncoding: 'BASE32' tells Keycloak to Base32-decode the stored value before
          # using it as the HMAC key. Without this, Keycloak uses raw UTF-8 bytes of the string,
          # which does not match what authenticator apps produce (they Base32-decode the secret
          # from the QR code). Devise stores secrets as Base32 strings, so this is required.
          credentialData: {
            subType: 'totp', digits: 6, counter: 0, period: 30, algorithm: 'HmacSHA1',
            secretEncoding: 'BASE32'
          }.to_json,
        }
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
