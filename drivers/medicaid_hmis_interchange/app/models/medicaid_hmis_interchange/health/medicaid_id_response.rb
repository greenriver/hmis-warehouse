###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes an insurance eligibility response and contains PHI
# Control: PHI attributes documented

require 'stupidedi'
module MedicaidHmisInterchange::Health
  class MedicaidIdResponse < HealthBase
    phi_attr :response, Phi::Bulk, 'Description of eligibility inquiry response' # contains EDI serialized PHI

    belongs_to :medicaid_id_inquiry, class_name: 'MedicaidHmisInterchange::Health::MedicaidIdInquiry', optional: true

    def TRN(subscriber) # rubocop:disable Naming/MethodName
      @sender ||= Health::Cp.sender.first
      subscriber['2000C SUBSCRIBER LEVEL'].
        select { |h| h.keys.include? :TRN }.map { |h| h[:TRN] }.
        each do |trn|
          source = trn.detect { |h| h.keys.include? :E509 }[:E509][:value][:raw]
          return trn.detect { |h| h.keys.include? :E127 }[:E127][:value][:raw] if source == @sender.trace_id
        end
      return nil
    end

    def medicaid_id(subscriber)
      subscriber['2000C SUBSCRIBER LEVEL'].
        detect { |h| h.keys.include? '2100C SUBSCRIBER NAME' }['2100C SUBSCRIBER NAME'].
        detect { |h| h.keys.include? :NM1 }[:NM1].
        detect { |h| h.keys.include? :E67 }[:E67][:value][:raw]
    end

    def subscribers
      return [] unless as_json.present?

      @subscribers ||= as_json[:interchanges].
        detect { |h| h.keys.include? :functional_groups }[:functional_groups].
        detect { |h| h.keys.include? :transactions }[:transactions].
        select { |h| h.keys.include? '2 - Subscriber Detail' }.
        map { |h| h['2 - Subscriber Detail'] }.flatten
    end

    def as_json
      return {} unless response.present?

      @as_json ||= begin
        json = {}
        parsed_271 = parse_271
        return {} unless parsed_271.present?

        parsed_271.zipper.tap { |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_271
      return nil unless response.present?

      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Parser::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(response))
      result.explain { |reason| raise reason + " at #{result.position.inspect}" } if result.fatal?
      return parsed
    end
  end
end
