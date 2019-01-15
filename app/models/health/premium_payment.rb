# ### HIPPA Risk Assessment
# Risk: Attached content contains EDI serialized PHI
# Control: PHI attributes documented

require "stupidedi"
module Health
  class PremiumPayment < HealthBase
    acts_as_paranoid

    phi_attr :id, Phi::SmallPopulation
    phi_attr :content, Phi::Bulk # contains EDI serialized PHI

    mount_uploader :file, PremiumPaymentFileUploader

    belongs_to :user

    def summary
      # NOTE: https://github.com/irobayna/stupidedi/issues/13
      @summary = {}

      parse_820.first.flatmap{|m| m.find(:GS) }.tap do |gs|
        el(gs, 3) do |e|
          @summary[:pid] = e[0, e.length - 1]
          @summary[:sl] = e[-1]
        end
        gs.iterate(:ST) do |st|
          st.iterate(:BPR) do |bpr|
            el(bpr, 2) do |e|
              @summary[:total_amount_paid] = e.to_i
            end
            bpr.find(:DTM).tap do |dtm|
              el(dtm, 6) do |e|
                @summary[:date_range] = (e.to_date..e.to_date)
              end
            end
            binding.pry
          end
        end
      end

      binding.pry
      return @summary
    end

    def to_json
      json = {}
      parse_820.zipper.tap do |z|
        Stupidedi::Writer::Json.new(z.root.node).write(json)
      end
      return json
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