# ### HIPAA Risk Assessment
# Risk:
# Control:

require "stupidedi"
module Health
  class EligibilityInquiry < HealthBase
    before_create :assign_control_numbers

    scope :pending, -> () do
      where(result: nil)
    end

    def build_inquiry_file
      self.inquiry ||= begin
        build_inquiry_edi
        convert_to_text
      end
    end

    private def build_inquiry_edi
      config = Stupidedi::Config.hipaa
      b = Stupidedi::Builder::BuilderDsl.build(config)
      hl = 0

      sender = Health::Cp.sender.first
      sender_id = "#{sender.pid}#{sender.sl}"
      application_id = id&.to_s

      b.ISA '00', b.blank, '00', b.blank, 'ZZ', sender_id, 'ZZ', sender.receiver_id, created_at, created_at, '^', '00501', isa_control_number, '0', interchange_usage_indicator, '>'
      b.GS 'HS', sender_id, sender.receiver_id, created_at, created_at.strftime('%H%M'), group_control_number, 'X', '005010X279A1'
      b.ST '270', transaction_control_number, '005010X279A1'
      b.BHT '0022', '13', application_id, created_at, created_at.strftime('%H%M')
      # Information source
      hl += 1
      b.HL hl, b.blank, '20', '1'
      b.NM1 'PR', '2', sender.receiver_name, b.blank, b.blank, b.blank, b.blank, '46', sender.receiver_id
      # Information receiver
      hl += 1
      b.HL hl, '1', '21', '1'
      b.NM1 '1P', '2', sender.mmis_enrollment_name, b.blank, b.blank, b.blank, b.blank, 'XX', sender.npi

      subscribers.each do |subscriber|
        # Subscriber information
        hl += 1
        b.HL hl, '2', '22', '0'
        # Use the subscriber's medicaid id as the trace record number
        b.TRN '1', subscriber.medicaid_id, sender.trace_id
        b.NM1 'IL', '1', subscriber.last_name, subscriber.first_name, subscriber.middle_name, b.blank, b.blank, 'MI', subscriber.medicaid_id
        b.DMG 'D8', subscriber.birthdate&.strftime('%Y%m%d'), subscriber.gender
        b.DTP '291', 'D8', service_date.strftime('%Y%m%d')
        b.EQ(
            b.repeated '30'
        )
      end

      m = b.machine
      st = m
      while st.segment.fetch.node.id != :ST
        st = st.parent.fetch
      end

      b.SE 2 + m.distance(st).fetch, transaction_control_number
      b.GE '1', group_control_number
      b.IEA '1', isa_control_number

      @edi_builder = b
    end

    private def convert_to_text
      file = ''
      @edi_builder.machine.zipper.tap do |z|
        separators = Stupidedi::Reader::Separators.build(
            segment: "~\n",
            element: "*",
            component: ">",
            repetition:  "^"
        )
        w = Stupidedi::Writer::Default.new(z.root, separators)
        file = w.write().upcase
      end
      return file
    end

    private def subscribers
      Health::Patient.all
    end

    private def interchange_usage_indicator
      Rails.env.production? ? 'P' : 'T'
    end

    private def assign_control_numbers
      self.isa_control_number = self.class.next_isa_control_number
      self.group_control_number = self.class.next_group_control_number
      self.transaction_control_number = self.class.next_transaction_control_number
    end

    def self.next_isa_control_number
      isa_control_number = maximum(:isa_control_number) || 10
      isa_control_number += 1
    end

    def self.next_group_control_number
      group_control_number = maximum(:group_control_number) || 1010
      group_control_number += 1
    end

    def self.next_transaction_control_number
      transaction_control_number = maximum(:transaction_control_number) || 1010
      transaction_control_number += 1
    end
  end
end