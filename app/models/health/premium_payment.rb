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

    end

    def parse_820
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Builder::StateMachine.build(config)
      parse, result = parser.read(Stupidedi::Reader.build(content))
      return result
    end

  end
end