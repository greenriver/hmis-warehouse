###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :sandbox do
  desc 'Neutralize external-integration credentials in a production snapshot (needs SANDBOX_MODE=true and SANDBOX_SCRUB_CONFIRM=<RAILS_ENV>)'
  task scrub: :environment do
    SandboxMode::Scrubber.authorize!(env: Rails.env, confirm: ENV['SANDBOX_SCRUB_CONFIRM'], sandbox_mode: SandboxMode.enabled?)
    puts 'Each database is scrubbed in its own transaction. If this stops partway, rerun it; the scrub is idempotent.'
    SandboxMode::Scrubber.new.run!.each { |table, count| puts "#{table}: #{count}" }
  rescue SandboxMode::Scrubber::Refused => e
    abort e.message
  end
end
