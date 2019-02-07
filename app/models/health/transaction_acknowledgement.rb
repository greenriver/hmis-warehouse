# ### HIPPA Risk Assessment
# NOT ASSESSED

require "stupidedi"
stupidedi_dir = Gem::Specification.find_by_name("stupidedi").gem_dir
json_dir = "#{stupidedi_dir}/notes/json_writer/"
Dir["#{json_dir}/json/*.rb"].each{ |file| require file }
require "#{json_dir}/json"
module Health
  class TransactionAcknowledgement  < HealthBase
    acts_as_paranoid

    mount_uploader :file, TransactionAcknowledgementFileUploader

    belongs_to :user

    def transaction_result
      begin
        data = as_json[:interchanges].
            detect{|h| h.keys.include? :functional_groups}[:functional_groups].
            detect{|h| h.keys.include? :transactions}[:transactions].
            detect{|h| h.keys.include? "Table 1 - Header"}["Table 1 - Header"].
            detect{|h| h.keys.include? :AK9}[:AK9]

        status = data.detect{|h| h.keys.include? :E715}[:E715][:value][:description]
        return status.downcase
      rescue
        return "error"
      end
    end

    def as_json
      @json ||= begin
        json = {}
        parse_999.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_999
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Builder::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(content))
      if result.fatal?
        result.explain{|reason| raise reason + " at #{result.position.inspect}" }
      end
      return parsed
    end
  end
end
