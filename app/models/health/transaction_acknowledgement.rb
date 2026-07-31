###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# NOT ASSESSED

require 'stupidedi'
module Health
  class TransactionAcknowledgement < HealthBase
    include FileContentValidator
    acts_as_paranoid

    # Remove CarrierWave dependency
    # mount_uploader :file, TransactionAcknowledgementFileUploader

    belongs_to :user, optional: true

    validate :validate_file_content_if_present

    # File contents are retained in the database (see the content column); they contain PHI and
    # must not be moved to the warehouse S3 bucket.
    def validate_file_content_if_present
      return if content.blank?

      file_extension = '.txt'
      allowed_types = ['text/plain', 'application/octet-stream']

      result = self.class.validate_file_content(
        content,
        nil,
        allowed_types,
        file_extension,
      )

      return if result[:valid]

      errors.add(:file, result[:error])
    end

    def transaction_result
      data = as_json[:interchanges].
        detect { |h| h.keys.include?(:functional_groups) }[:functional_groups].
        detect { |h| h.keys.include?(:transactions) }[:transactions].
        detect { |h| h.keys.include?('1 - Header') }['1 - Header'].
        detect { |h| h.keys.include?(:AK9) }[:AK9]

      status = data.detect { |h| h.keys.include?(:E715) }[:E715][:value][:description]
      status.downcase
    rescue StandardError
      'error'
    end

    def transaction_counts
      data = as_json[:interchanges].
        detect { |h| h.keys.include?(:functional_groups) }[:functional_groups].
        detect { |h| h.keys.include?(:transactions) }[:transactions].
        detect { |h| h.keys.include?('1 - Header') }['1 - Header'].
        detect { |h| h.keys.include?(:AK9) }[:AK9]

      included = data.detect { |h| h.keys.include?(:E97) }[:E97]
      received = data.detect { |h| h.keys.include?(:E123) }[:E123]
      accepted = data.detect { |h| h.keys.include?(:E2) }[:E2]

      {
        included[:name] => included[:value][:raw],
        received[:name] => received[:value][:raw],
        accepted[:name] => accepted[:value][:raw],
      }
    rescue StandardError
      {}
    end

    def error_messages
      as_json[:interchanges].
        detect { |h| h.keys.include?(:functional_groups) }[:functional_groups].
        detect { |h| h.keys.include?(:transactions) }[:transactions].
        detect { |h| h.keys.include?('1 - Header') }['1 - Header'].
        detect { |h| h.keys.include?('2000 TRANSACTION SET RESPONSE HEADER') }['2000 TRANSACTION SET RESPONSE HEADER'].
        detect { |h| h.keys.include?(:IK5) }[:IK5].
        select { |h| h.keys.include?(:E618) }.
        flat_map(&:values).
        flat_map { |m| m[:value][:description] }.
        compact
    rescue StandardError
      []
    end

    def as_json
      @as_json ||= begin
        json = {}
        parse_999.zipper.tap { |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_999
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Parser::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(content))
      result.explain { |reason| raise reason + " at #{result.position.inspect}" } if result.fatal?
      parsed
    end
  end
end
