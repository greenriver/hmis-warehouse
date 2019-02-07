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
      data = as_json[:interchanges].
          detect{|h| h.keys.include? :functional_groups}[:functional_groups].
          detect{|h| h.keys.include? :transactions}[:transactions].
          detect{|h| h.keys.include? "Table 1 - Header"}["Table 1 - Header"].
          detect{|h| h.keys.include? :AK9}[:AK9]

      status = data.detect{|h| h.keys.include? :E715}[:E715][:value][:description]
      status.downcase
    end

    def as_json
      @json ||= begin
        json = {}
        parse_999.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_999
      content = "ISA*00*          *00*          *ZZ*DMA7384        *ZZ*110020876R     *181217*1122*^*00501*000000004*0*P*:~GS*FA*DMA7384*110020876R*20181217*11224990*4*X*005010X231A1~ST*999*4001*005010X231A1~AK1*HC*1020*005010X222A1~AK2*837*0079*005010X222A1~IK3*LX*889*2400*8~CTX*CLM01:62~IK4*1**6*21~IK3*LX*892*2400*8~CTX*CLM01:62~IK4*1**6*22~IK3*LX*895*2400*8~CTX*CLM01:62~IK4*1**6*23~IK3*LX*898*2400*8~CTX*CLM01:62~IK4*1**6*24~IK3*LX*1059*2400*8~CTX*CLM01:68~IK4*1**6*21~IK3*LX*1062*2400*8~CTX*CLM01:68~IK4*1**6*22~IK3*LX*1065*2400*8~CTX*CLM01:68~IK4*1**6*23~IK3*LX*1068*2400*8~CTX*CLM01:68~IK4*1**6*24~IK3*LX*1071*2400*8~CTX*CLM01:68~IK4*1**6*25~IK3*LX*1074*2400*8~CTX*CLM01:68~IK4*1**6*26~IK3*LX*1727*2400*8~CTX*CLM01:95~IK4*1**6*21~IK3*LX*3901*2400*8~CTX*CLM01:281~IK4*1**6*21~IK3*LX*3904*2400*8~CTX*CLM01:281~IK4*1**6*22~IK3*LX*4941*2400*8~CTX*CLM01:346~IK4*1**6*21~IK3*LX*4944*2400*8~CTX*CLM01:346~IK4*1**6*22~IK3*LX*4947*2400*8~CTX*CLM01:346~IK4*1**6*23~IK3*LX*4950*2400*8~CTX*CLM01:346~IK4*1**6*24~IK3*LX*6038*2400*8~CTX*CLM01:435~IK4*1**6*21~IK3*LX*7753*2400*8~CTX*CLM01:363~IK4*1**6*21~IK3*LX*7756*2400*8~CTX*CLM01:363~IK4*1**6*22~IK3*LX*7759*2400*8~CTX*CLM01:363~IK4*1**6*23~IK3*LX*7762*2400*8~CTX*CLM01:363~IK4*1**6*24~IK3*LX*7765*2400*8~CTX*CLM01:363~IK4*1**6*25~IK3*LX*7768*2400*8~CTX*CLM01:363~IK4*1**6*26~IK3*LX*7771*2400*8~CTX*CLM01:363~IK4*1**6*27~IK3*LX*7774*2400*8~CTX*CLM01:363~IK4*1**6*28~IK3*LX*7848*2400*8~CTX*CLM01:251~IK4*1**6*21~IK3*LX*7851*2400*8~CTX*CLM01:251~IK4*1**6*22~IK3*LX*7979*2400*8~CTX*CLM01:502~IK4*1**6*21~IK3*LX*7982*2400*8~CTX*CLM01:502~IK4*1**6*22~IK3*LX*8308*2400*8~CTX*CLM01:571~IK4*1**6*21~IK3*LX*8311*2400*8~CTX*CLM01:571~IK4*1**6*22~IK3*LX*8314*2400*8~CTX*CLM01:571~IK4*1**6*23~IK3*LX*8317*2400*8~CTX*CLM01:571~IK4*1**6*24~IK3*LX*8320*2400*8~CTX*CLM01:571~IK4*1**6*25~IK3*LX*8323*2400*8~CTX*CLM01:571~IK4*1**6*26~IK3*LX*8326*2400*8~CTX*CLM01:571~IK4*1**6*27~IK3*LX*8329*2400*8~CTX*CLM01:571~IK4*1**6*28~IK3*LX*8332*2400*8~CTX*CLM01:571~IK4*1**6*29~IK3*LX*8335*2400*8~CTX*CLM01:571~IK4*1**6*30~IK3*LX*8338*2400*8~CTX*CLM01:571~IK4*1**6*31~IK3*LX*8341*2400*8~CTX*CLM01:571~IK4*1**6*32~IK3*LX*8344*2400*8~CTX*CLM01:571~IK4*1**6*33~IK3*LX*8347*2400*8~CTX*CLM01:571~IK4*1**6*34~IK3*LX*8350*2400*8~CTX*CLM01:571~IK4*1**6*35~IK3*LX*8353*2400*8~CTX*CLM01:571~IK4*1**6*36~IK3*LX*8356*2400*8~CTX*CLM01:571~IK4*1**6*37~IK3*LX*8359*2400*8~CTX*CLM01:571~IK4*1**6*38~IK3*LX*8362*2400*8~CTX*CLM01:571~IK4*1**6*39~IK5*R*I5*4~AK9*R*1*1*0~SE*153*4001~GE*1*4~IEA*1*000000004~"

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
