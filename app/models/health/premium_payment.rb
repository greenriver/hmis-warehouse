# ### HIPPA Risk Assessment
# Risk: Attached content contains EDI serialized PHI
# Control: PHI attributes documented

require "stupidedi"
stupidedi_dir = Gem::Specification.find_by_name("stupidedi").gem_dir
json_dir = "#{stupidedi_dir}/notes/json_writer/"
Dir["#{json_dir}/json/*.rb"].each{ |file| require file }
require "#{json_dir}/json"
module Health
  class PremiumPayment < HealthBase
    acts_as_paranoid

    phi_attr :id, Phi::SmallPopulation
    phi_attr :content, Phi::Bulk # contains EDI serialized PHI

    mount_uploader :file, PremiumPaymentFileUploader

    belongs_to :user

    def summary
      
      @summary = {}
      gs = as_json[:interchanges].detect{|h| h.keys.include? :functional_groups}[:functional_groups].first[:GS].map(&:values).flatten
      pid_sl = gs.detect{|h| h[:name] == "Application Receiver's Code"}[:value][:raw]
      @summary[:pid] = pid_sl[0, pid_sl.length - 1]
      @summary[:sl] = pid_sl[-1]

      headers = as_json[:interchanges].detect{|h| h.keys.include? :functional_groups}[:functional_groups].
        detect{|h| h.keys.include? :transactions}[:transactions].first.values.flatten

      bpr = headers.detect{|h| h.keys.include? :BPR}[:BPR].map(&:values).flatten

      total_amount_paid = bpr[1][:value][:raw]&.to_f
      @summary[:total_amount_paid] = total_amount_paid

      dtm = headers.detect{|h| h.keys.include? :DTM}[:DTM].map(&:values).flatten
      date_range = dtm[5][:value][:raw].split('-').map(&:to_date)
      @summary[:start_date] = date_range.first
      @summary[:start_date] = date_range.last

      # We're leaving this here for future development, but using the json writer is more efficient currently
      # NOTE: https://github.com/irobayna/stupidedi/issues/13
      # parse_820.first.flatmap{|m| m.find(:GS) }.tap do |gs|
      #   el(gs, 3) do |e|
      #     @summary[:pid] = e[0, e.length - 1]
      #     @summary[:sl] = e[-1]
      #   end
      #   gs.iterate(:ST) do |st|
      #     st.iterate(:BPR) do |bpr|
      #       el(bpr, 2) do |e|
      #         @summary[:total_amount_paid] = e.to_i
      #       end
      #       bpr.find(:DTM).tap do |dtm|
      #         el(dtm, 6) do |e|
      #           @summary[:date_range] = (e.to_date..e.to_date)
      #         end
      #       end
      #     end
      #   end
      # end
      return @summary
    end

    def as_json
      @json ||= begin
        json = {}
        parse_820.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def details
      @details = []
      data = as_json[:interchanges].detect{|h| h.keys.include? :functional_groups}[:functional_groups].detect{|h| h.keys.include? :transactions}[:transactions].select{|h| h.keys.include? "Table 2 - Detail"}
      data.each do |_, patient|
        ent = patient.detect{|h| h.keys.include? :ENT}.values.flatten.map(&:values).flatten
        nm1 = patient.detect{|h| h.keys.include? :NM1}.values.flatten.map(&:values).flatten
        rmr = patient.detect{|h| h.keys.include? :RMR}.values.flatten.map(&:values).flatten
        dtm = patient.detect{|h| h.keys.include? :DTM}.values.flatten.map(&:values).flatten
        mass_health_id = ent[3][:value][:raw]
        first_name = nm1[3][:value][:raw]
        last_name = nm1[2][:value][:raw]
        middle_name = nm1[4][:value][:raw]
        sender_code = rmr[1][:value][:raw]
        premium_payment = rmr[3][:value][:raw]
        premium_billed = rmr[4][:value][:raw]
        date_time_qualifier dtm[0][:value][:raw]
        date = dtm[1][:value][:raw]
        time = dtm[2][:value][:raw]
        # @details << 
      end
    end

    def parse_820
      @parse_820 ||= begin
        config = Stupidedi::Config.contrib
        parser = Stupidedi::Builder::StateMachine.build(config)
        # .gsub('~', "~\n")
        parsed, result = parser.read(Stupidedi::Reader.build(content))
        if result.fatal?
          result.explain{|reason| raise reason + " at #{result.position.inspect}" }
        end
        parsed
      end
    end


    # Helper function: fetch an element from the current segment
    def el(m, *ns, &block)
      if Stupidedi::Either === m
        m.tap{|m| el(m, *ns, &block) }
      else
        yield(*ns.map{|n| m.elementn(n).map(&:value).fetch })
      end
    end

  end
end