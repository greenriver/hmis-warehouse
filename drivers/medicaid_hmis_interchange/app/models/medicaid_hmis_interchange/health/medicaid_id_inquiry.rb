###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes an insurance eligibility inquiry and contains PHI
# Control: PHI attributes documented

require 'stupidedi'

module MedicaidHmisInterchange::Health
  class MedicaidIdInquiry < HealthBase
    before_create :assign_control_numbers

    phi_attr :inquiry, Phi::Bulk, 'Description of inquiry' # contains EDI serialized PHI
    phi_attr :result, Phi::Bulk, 'Result of inquiry' # contains EDI serialized PHI
    attr_accessor :clients

    has_one :medicaid_id_response, dependent: :destroy

    def build_inquiry_file
      self.inquiry ||= begin
        build_inquiry_edi
        convert_to_text
      end
    end

    private def build_inquiry_edi
      config = Stupidedi::Config.hipaa
      b = Stupidedi::Parser::BuilderDsl.build(config)
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
      b.NM1 '1P', '2', sender.mmis_enrollment_name, b.blank, b.blank, b.blank, b.blank, 'SV', sender_id

      clients.each do |client|
        # Subscriber information
        hl += 1
        b.HL hl, '2', '22', '0'
        # Use the client's rails id as the trace record number
        b.TRN '1', client.id, sender.trace_id
        b.NM1 'IL', '1', client.last_name, client.first_name, client.middle_name
        b.REF 'SY', client.ssn
        b.DMG 'D8', client.dob&.strftime('%Y%m%d'), edi_gender(client)
        b.DTP '291', 'D8', service_date.strftime('%Y%m%d')
        b.EQ(b.repeated('30'))
      end

      m = b.machine
      st = m
      st = st.parent.fetch while st.segment.fetch.node.id != :ST

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
          element: '*',
          component: '>',
          repetition: '^',
        )
        w = Stupidedi::Writer::Default.new(z.root, separators)
        file = w.write.upcase
      end
      file
    end

    # DMG03 is optional, but if it appears, it can only have the values M, F
    private def edi_gender(client)
      case client.gender_binary
      when 0
        'F'
      when 1
        'M'
      end
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
      isa_control_number + 1
    end

    def self.next_group_control_number
      group_control_number = maximum(:group_control_number) || 1010
      group_control_number + 1
    end

    def self.next_transaction_control_number
      transaction_control_number = maximum(:transaction_control_number) || 1010
      transaction_control_number + 1
    end
  end
end
