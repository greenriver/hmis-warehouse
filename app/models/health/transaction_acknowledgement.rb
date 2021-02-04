###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# NOT ASSESSED

require 'stupidedi'
module Health
  class TransactionAcknowledgement < HealthBase
    acts_as_paranoid

    mount_uploader :file, TransactionAcknowledgementFileUploader

    belongs_to :user

    def transaction_result
      data = as_json[:interchanges].
        detect { |h| h.keys.include? :functional_groups }[:functional_groups].
        detect { |h| h.keys.include? :transactions }[:transactions].
        detect { |h| h.keys.include? '1 - Header' }['1 - Header'].
        detect { |h| h.keys.include? :AK9 }[:AK9]

      status = data.detect { |h| h.keys.include? :E715 }[:E715][:value][:description]
      return status.downcase
    rescue StandardError
      return 'error'
    end

    def transaction_counts
      data = as_json[:interchanges].
        detect { |h| h.keys.include? :functional_groups }[:functional_groups].
        detect { |h| h.keys.include? :transactions }[:transactions].
        detect { |h| h.keys.include? '1 - Header' }['1 - Header'].
        detect { |h| h.keys.include? :AK9 }[:AK9]

      included = data.detect { |h| h.keys.include? :E97 }[:E97]
      received = data.detect { |h| h.keys.include? :E123 }[:E123]
      accepted = data.detect { |h| h.keys.include? :E2 }[:E2]

      return {
        included[:name] => included[:value][:raw],
        received[:name] => received[:value][:raw],
        accepted[:name] => accepted[:value][:raw],
      }
    rescue StandardError
      return {}
    end

    def error_messages
      as_json[:interchanges].
        detect { |h| h.keys.include? :functional_groups }[:functional_groups].
        detect { |h| h.keys.include? :transactions }[:transactions].
        detect { |h| h.keys.include? '1 - Header' }['1 - Header'].
        detect { |h| h.keys.include? '2000 TRANSACTION SET RESPONSE HEADER' }['2000 TRANSACTION SET RESPONSE HEADER'].
        detect { |h| h.keys.include? :IK5 }[:IK5].
        select { |h| h.keys.include? :E618 }.
        flat_map { |m| m.values }.
        flat_map { |m| m[:value][:description] }.
        compact
    rescue StandardError
      []
    end

    def as_json
      @json ||= begin
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
      return parsed
    end
  end
end
