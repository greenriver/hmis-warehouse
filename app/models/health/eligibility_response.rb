# ### HIPAA Risk Assessment
# Risk:
# Control:

require "stupidedi"
stupidedi_dir = Gem::Specification.find_by_name("stupidedi").gem_dir
json_dir = "#{stupidedi_dir}/notes/json_writer/"
Dir["#{json_dir}/json/*.rb"].each{ |file| require file }
require "#{json_dir}/json"

module Health
  class EligibilityResponse < HealthBase

    belongs_to :eligibility_inquiry, class_name: Health::EligibilityInquiry

    def eligible_ids
      subscribers.select{|s| eligible(s) == true}.map{|s| TRN(s)}
    end

    def ineligible_ids
      subscribers.select{|s| eligible(s) == false}.map{|s| TRN(s)}
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
    end

    def eligible(subscriber)
      subscriber["2000C SUBSCRIBER LEVEL"].
        detect{|h| h.keys.include? "2100C SUBSCRIBER NAME"}["2100C SUBSCRIBER NAME"].
        select{|h| h.keys.include? "2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION"}.
          each do |info|
            code = info["2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION"].
              detect{|h| h.keys.include? :EB}[:EB].
              detect{|h| h.keys.include? :E1390}[:E1390][:value][:raw]
            return true if code == '1'
          end
      return false
    end

    def subscribers
      as_json[:interchanges].
        detect{|h| h.keys.include? :functional_groups}[:functional_groups].
        detect{|h| h.keys.include? :transactions}[:transactions].
        select{|h| h.keys.include? "Table 2 - Subscriber Detail"}.
          map{|h| h["Table 2 - Subscriber Detail"]}.flatten
    end

    def sender
      @sender ||= Health::Cp.sender.first
    end

    def as_json
      @json ||= begin
        json = {}
        parse_271.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_271
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
