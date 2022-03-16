###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
      where.not(inquiry: nil).
        where.not(id: Health::EligibilityResponse.select(:eligibility_inquiry_id))
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

      batch.each do |patient|
        # Subscriber information
        hl += 1
        b.HL hl, '2', '22', '0'
        # Use the patient's medicaid id as the trace record number
        b.TRN '1', patient.medicaid_id, sender.trace_id
        b.NM1 'IL', '1', patient.last_name, patient.first_name, patient.middle_name, b.blank, b.blank, 'MI', patient.medicaid_id
        b.DMG 'D8', patient.birthdate&.strftime('%Y%m%d'), edi_gender(patient.gender)
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
