###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Arm-specific examples must carry the `:devise_only` / `:jwt_only` tag, never a hand-written
# `if: AuthMethod.devise?` / `if: AuthMethod.jwt?` gate: both `if:` directions fail silently (the two
# examples below spell out how), and CI reads a silent skip as a pass. The tag keeps the example
# selected on exactly one arm instead of silently dropping it.
# See docs/features/warehouse/ci-test-bucketing.md for the arms.
RSpec.describe 'AUTH_METHOD arm tagging convention' do
  # Scan every .rb in both spec trees, not just *_spec.rb: a gate can sit in a shared example group
  # under spec/support that no CI --pattern matches directly. Exclude this file — its own example
  # descriptions quote the gates as string literals, which the comment-line reject below won't skip.
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
      # Skip comment lines: comments elsewhere quote the gates and would be flagged as false offenders.
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
