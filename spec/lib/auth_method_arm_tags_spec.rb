###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# An arm-specific example carries the `:devise_only` or `:jwt_only` tag and nothing else; see
# docs/features/warehouse/ci-test-bucketing.md for the arms themselves.
#
# A hand-written `if: AuthMethod.devise?` or `if: AuthMethod.jwt?` looks like a redundant restatement
# of the tag, but both directions fail quietly. An `if:`-gated example is skipped by the default (jwt)
# arm and not selected by the Devise step's `--tag devise_only`, so it runs on neither arm, and an
# unselected example is indistinguishable from a passing one in a CI log. Gated the other way, a
# wrong-arm local run reports "0 examples, 0 failures", which also reads as a pass. The tag raises and
# names the arm instead.
RSpec.describe 'AUTH_METHOD arm tagging convention' do
  # Both spec trees CI globs, and not just *_spec.rb: a gate can sit in a shared example group under
  # spec/support, which no --pattern of ours matches directly. This file is excluded because its own
  # prose quotes the gates.
  let(:scanned_files) do
    Dir.glob(
      [
        Rails.root.join('spec/**/*.rb'),
        Rails.root.join('drivers/*/spec/**/*.rb'),
      ],
    ).reject { |path| File.expand_path(path) == File.expand_path(__FILE__) }.sort
  end

  def offenders_for(gate)
    scanned_files.flat_map do |path|
      # Comments quote the gates in a few places, so match against code only.
      File.readlines(path).each_with_index.
        reject { |line, _index| line.lstrip.start_with?('#') }.
        select { |line, _index| line.match?(gate) }.
        map { |_line, index| "#{Pathname.new(path).relative_path_from(Rails.root)}:#{index + 1}" }
    end
  end

  it 'has no spec gated with `if: AuthMethod.devise?`, which would run on neither arm' do
    offenders = offenders_for(/if:\s*AuthMethod\.devise\?/)

    expect(offenders).to be_empty, <<~MSG
      Gated to the Devise arm by hand, so the Devise CI step never selects them and they run on
      neither arm:

      #{offenders.join("\n")}

      Drop the `if:` and tag the block :devise_only instead. spec/rails_helper.rb applies the arm.
    MSG
  end

  it 'has no spec gated with `if: AuthMethod.jwt?`, which reports zero examples on the wrong arm' do
    offenders = offenders_for(/if:\s*AuthMethod\.jwt\?/)

    expect(offenders).to be_empty, <<~MSG
      Gated to the JWT arm by hand, so running them under AUTH_METHOD=devise silently reports zero
      examples instead of naming the arm:

      #{offenders.join("\n")}

      Drop the `if:` and tag the block :jwt_only instead. spec/rails_helper.rb applies the arm.
    MSG
  end
end
