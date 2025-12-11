###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: Describes an insurance eligibility inquiry and contains PHI
# Control: PHI attributes documented

require 'stupidedi'
module Health
  class EligibilityInquiry < HealthBase
    before_create :assign_control_numbers
    after_initialize :set_batch

    phi_attr :inquiry, Phi::Bulk, 'Description of inquiry' # contains EDI serialized PHI
    phi_attr :result, Phi::Bulk, 'Result of inquiry' # contains EDI serialized PHI
    attr_accessor :batch

    has_one :eligibility_response, dependent: :destroy
    has_many :batches, class_name: 'Health::EligibilityInquiry', foreign_key: :batch_id, dependent: :destroy

    scope :pending, -> do
      where.not(inquiry: nil).where.missing(:eligibility_response)
    end

    scope :patients, -> do
      Health::Patient.participating.
        joins(:patient_referral).
        where.not(medicaid_id: nil)
    end

    def eligible_ids
      return eligibility_response.eligible_ids unless has_batch

      @eligible_ids ||= begin
        ids = []
        batch_responses.each do |response|
          ids += response.eligible_ids
        end
        ids.uniq
      end
    end

    def ineligible_ids
      return eligibility_response.ineligible_ids unless has_batch

      @ineligible_ids ||= begin
        ids = []
        batch_responses.each do |response|
          ids += response.ineligible_ids
        end
        ids.uniq
      end
    end

    def managed_care_ids
      return eligibility_response.managed_care_ids unless has_batch

      @managed_care_ids ||= begin
        ids = []
        batch_responses.each do |response|
          ids += response.managed_care_ids
        end
        ids.uniq
      end
    end

    def aco_names
      return eligibility_response.aco_names unless has_batch

      @aco_names ||= begin
        names = {}
        batch_responses.each do |response|
          names.merge!(response.aco_names)
        end
        names
      end
    end

    def patient_aco_changes
      return eligibility_response.patient_aco_changes unless has_batch

      @patient_aco_changes ||= begin
        changes = {}
        batch_responses.each do |response|
          changes.merge!(response.patient_aco_changes || {})
        end
        changes
      end
    end

    def batch_responses
      @batch_responses ||= Health::EligibilityResponse.where(eligibility_inquiry_id: batches.select(:id))
    end

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

      # Ensure all string values are mutable to avoid frozen string literal warnings
      # Stupidedi builder methods are mutating the string within the gem flagging the frozen string literal warnings.
      b.ISA(*mutable_args('00', b.blank, '00', b.blank, 'ZZ', sender_id, 'ZZ', sender.receiver_id.to_s, created_at, created_at, '^', '00501', isa_control_number.to_s, '0', interchange_usage_indicator.to_s, '>'))
      b.GS(*mutable_args('HS', sender_id, sender.receiver_id, created_at, created_at.strftime('%H%M'), group_control_number, 'X', '005010X279A1'))
      b.ST(*mutable_args('270', transaction_control_number, '005010X279A1'))
      b.BHT(*mutable_args('0022', '13', application_id, created_at, created_at.strftime('%H%M')))
      # Information source
      hl += 1
      b.HL(*mutable_args(hl, b.blank, '20', '1'))
      b.NM1(*mutable_args('PR', '2', sender.receiver_name, b.blank, b.blank, b.blank, b.blank, '46', sender.receiver_id))
      # Information receiver
      hl += 1
      b.HL(*mutable_args(hl, '1', '21', '1'))
      b.NM1(*mutable_args('1P', '2', sender.mmis_enrollment_name, b.blank, b.blank, b.blank, b.blank, 'XX', sender.npi))

      batch.each do |patient|
        # Subscriber information
        hl += 1
        b.HL(*mutable_args(hl, '2', '22', '0'))
        # Use the patient's medicaid id as the trace record number
        b.TRN(*mutable_args('1', patient.medicaid_id, sender.trace_id))
        b.NM1(*mutable_args('IL', '1', patient.last_name, patient.first_name, patient.middle_name, b.blank, b.blank, 'MI', patient.medicaid_id))
        b.DMG(*mutable_args('D8', patient.birthdate&.strftime('%Y%m%d'), edi_gender(patient.gender)))
        b.DTP(*mutable_args('291', 'D8', service_date.strftime('%Y%m%d')))
        b.EQ(b.repeated(*mutable_args('30')))
      end

      m = b.machine
      st = m
      st = st.parent.fetch while st.segment.fetch.node.id != :ST

      b.SE(*mutable_args(2 + m.distance(st).fetch, transaction_control_number))
      b.GE(*mutable_args('1', group_control_number))
      b.IEA(*mutable_args('1', isa_control_number))

      @edi_builder = b
    end

    # Helper method to make strings in an argument array mutable
    # Preserves special objects like b.blank and non-string values like dates
    private def mutable_args(*args)
      args.map do |arg|
        arg.is_a?(String) ? arg.dup : arg
      end
    end

    private def convert_to_text
      file = ''
      @edi_builder.machine.zipper.tap do |z|
        # Stupidedi to mutate the strings within the gem flagging the frozen string literal warnings. The strings are duped to avoid the warnings.
        separators = Stupidedi::Reader::Separators.build(
          segment: "~\n".dup,
          element: '*'.dup,
          component: '>'.dup,
          repetition: '^'.dup,
        )
        w = Stupidedi::Writer::Default.new(z.root, separators)
        # Pass a mutable string buffer to avoid frozen string literal warnings
        # The gem's write method has a default parameter "" which is frozen in Ruby 3.4
        file = w.write(String.new).upcase
      end
      file
    end

    # DMG03 is optional, but if it appears, it can only have the values M, F
    private def edi_gender(gender)
      @valid_gender ||= ['M', 'F', 'Trans F to M', 'Trans M to F']
      gender.last if @valid_gender.include?(gender)
    end

    private def interchange_usage_indicator
      Rails.env.production? ? 'P' : 'T'
    end

    private def assign_control_numbers
      self.isa_control_number = self.class.next_isa_control_number
      self.group_control_number = self.class.next_group_control_number
      self.transaction_control_number = self.class.next_transaction_control_number
    end

    private def set_batch
      self.batch = self.class.patients unless batch.present?
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
