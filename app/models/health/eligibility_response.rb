# ### HIPAA Risk Assessment
# Risk: Describes an insurance eligibility response and contains PHI
# Control: PHI attributes documented

require "stupidedi"
stupidedi_dir = Gem::Specification.find_by_name("stupidedi").gem_dir
json_dir = "#{stupidedi_dir}/notes/json_writer/"
Dir["#{json_dir}/json/*.rb"].each{ |file| require file }
require "#{json_dir}/json"

module Health
  class EligibilityResponse < HealthBase
    acts_as_paranoid

    phi_attr :response, Phi::Bulk # contains EDI serialized PHI

    mount_uploader :file, EligibilityResponseFileUploader

    belongs_to :eligibility_inquiry, class_name: Health::EligibilityInquiry
    belongs_to :user

    def subscriber_ids
      @subs ||= subscribers.map{|s| TRN(s)}
    end

    def eligible_ids
      @eligibles ||= subscribers.select{|s| eligible(s) == true}.map{|s| TRN(s)}
    end

    def managed_care_ids
      @manageds ||= subscribers.select{|s| managed_care(s) == true}.map{|s| TRN(s)}
    end

    def ineligible_ids
      @ineligibles ||= subscribers.select{|s| eligible(s) == false}.map{|s| TRN(s)}
    end

    def eligible_clients
      count = self.num_eligible
      count ||= begin
        count = eligible_ids.count
        update(num_eligible: count)
        count
      end
    end

    def ineligible_clients
      count = num_ineligible
      count ||= begin
        count = ineligible_ids.count
        update(num_ineligible: count)
        count
      end
    end

    def TRN(subscriber)
      subscriber["2000C SUBSCRIBER LEVEL"].
        select{|h| h.keys.include? :TRN}.map{|h| h[:TRN]}.
          each do |trn|
            source = trn.detect{|h| h.keys.include? :E509}[:E509][:value][:raw]
            if source == sender.trace_id
              return  trn.detect{|h| h.keys.include? :E127}[:E127][:value][:raw]
            end
          end
      return nil
    end

    def eligible(subscriber)
      EB(subscriber).detect{ |eb| eb.first == '1' }
    end

    def managed_care(subscriber)
      ebs = EB(subscriber)
      ebs.detect{ |eb| eb.first == 'MC' } || ebs.detect{ |eb| eb.first == 'L' && eb.last.include?('ACO') }
    end

    def EB(subscriber)
      codes = []
      text = []
      subscriber["2000C SUBSCRIBER LEVEL"].
          detect{|h| h.keys.include? "2100C SUBSCRIBER NAME"}["2100C SUBSCRIBER NAME"].
          select{|h| h.keys.include? "2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION"}.
        each do |info|
          ebs = info["2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION"].
            detect{|h| h.keys.include? :EB}[:EB]
          codes << ebs.detect{|h| h.keys.include? :E1390}[:E1390][:value][:raw]
          text << ebs.detect{|h| h.keys.include? :E1204}[:E1204][:value][:raw]
        end
      return codes.zip(text)
    end

    def subscribers
      return [] unless as_json.present?
      @json_subs ||= as_json[:interchanges].
        detect{|h| h.keys.include? :functional_groups}[:functional_groups].
        detect{|h| h.keys.include? :transactions}[:transactions].
        select{|h| h.keys.include? "Table 2 - Subscriber Detail"}.
          map{|h| h["Table 2 - Subscriber Detail"]}.flatten
    end

    def sender
      @sender ||= Health::Cp.sender.first
    end

    def as_json
      return {} unless response.present?
      @json ||= begin
        json = {}
        parsed_271 = parse_271
        return {} unless parsed_271.present?
        parsed_271.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_271
      return nil unless response.present?
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Builder::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(response))
      if result.fatal?
        result.explain{|reason| raise reason + " at #{result.position.inspect}" }
      end
      return parsed
    end
  end
end
