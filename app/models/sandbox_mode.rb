###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Switch for running a production snapshot without contacting external partners.
# Only the exact value "true" turns it on; ENV is read on every call.
module SandboxMode
  class IntegrationDisabled < StandardError; end

  def self.enabled?
    ENV['SANDBOX_MODE'] == 'true'
  end

  # Use in `active` scopes: `SandboxMode.filter(where(active: true))`
  def self.filter(relation)
    enabled? ? relation.none : relation
  end

  # Use at an outbound call that has no config lookup to scope.
  def self.guard!(integration_name)
    raise IntegrationDisabled, "#{integration_name} is disabled in sandbox mode" if enabled?

    nil
  end

  def self.config_warnings
    warnings = []
    mode = ENV['SANDBOX_MODE']
    if enabled?
      warnings << 'SANDBOX_MODE is on: external integrations are disabled'
    elsif mode.present?
      warnings << "SANDBOX_MODE is set to #{mode.inspect} and is ignored; only \"true\" enables sandbox mode"
    end

    domains = ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS']
    if domains
      count = domains.split(',').map(&:strip).reject(&:blank?).size
      warnings << "SANDBOX_EMAIL_ALLOWED_DOMAINS is set: outgoing email is limited to #{count} allowed domain(s)"
    end
    warnings
  end
end
