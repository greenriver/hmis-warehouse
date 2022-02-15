###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Attached claims_file contains EDI serialized PHI
# Control: PHI attributes documented

require "stupidedi"
module Health
  class Claim < HealthBase
    include ArelHelper
    acts_as_paranoid

    phi_attr :id, Phi::SmallPopulation, "ID of claim"
    phi_attr :claims_file, Phi::Bulk # contains EDI serialized PHI

    has_many :qualifying_activities
    validates_presence_of :max_date

    scope :visible_by?, -> (user) do
      if user.can_administer_health?
        all
      else
        none
      end
    end

    scope :unsubmitted, -> do
      where submitted_at: nil
    end

    scope :submitted, -> do
      where.not submitted_at: nil
    end

    scope :completed, -> do
      where.not completed_at: nil
    end

    scope :started, -> do
      where.not started_at: nil
    end

    scope :incomplete, -> do
      started.where completed_at: nil
    end

    scope :queued, -> do
      where started_at: nil, precalculated_at: nil
    end

    scope :precalculated, -> do
      where.not(precalculated_at: nil).where(started_at: nil)
    end

    def submitted?
      submitted_at.present?
    end

    def patients
      Health::Patient.joins(:patient_referral).
        where(id: qualifying_activities.select(:patient_id).distinct)
    end

    def pre_calculate_qualifying_activity_payability!
      attach_quailifying_activities_to_report
      qualifying_activities.each(&:calculate_payability!)
      update(precalculated_at: Time.now)
    end

    def run!
      start_report
      build_claims_file
      self.claims_file = convert_claims_to_text
      mark_qualifying_activites_as_submitted unless test_file
      complete_report
    end


    def claims_file_valid?
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Builder::StateMachine.build(config)
      parse, result = parser.read(Stupidedi::Reader.build(claims_file))
      return result
    end

    def build_claims_file
      @isa_control_number = self.class.next_isa_control_number
      @group_control_number = self.class.next_group_control_number
      @st_control_number = self.class.next_st_control_number
      @hl = 0
      @sender = Health::Cp.sender.first
      created_at ||= Time.now.utc
      config = Stupidedi::Config.hipaa
      b = Stupidedi::Builder::BuilderDsl.build(config)
      s = Stupidedi::Builder::IdentifierStack.new(1)

      b.ISA "00", '', "00", '', 'ZZ', "#{@sender.pid}#{@sender.sl}", 'ZZ', @sender.receiver_id, created_at, created_at, repetition_separator, '00501', @isa_control_number, '0', interchange_usage_indicator, component_element_separator
      b.GS 'HC', "#{@sender.pid}#{@sender.sl}", @sender.receiver_id, created_at, created_at, @group_control_number, 'X', implementation_convention_reference_number
      b.ST "837", id&.to_s&.rjust(4, '0') || '0'.rjust(4, '0'), implementation_convention_reference_number
        b.BHT "0019", "00", id&.to_s&.rjust(4, '0') || '0'.rjust(4, '0'), created_at, created_at.strftime('%H%M'), "CH"
        b.NM1 '41', '2', @sender.mmis_enrollment_name, nil, nil, nil, nil, "46", "#{@sender.pid}#{@sender.sl}"
        b.PER "IC", "#{@sender.key_contact_first_name} #{@sender.key_contact_last_name}", 'TE', @sender.key_contact_phone.delete('^0-9')
        b.NM1 "40", "2", @sender.receiver_name, nil, nil, nil, nil, "46", @sender.receiver_id
          @hl += 1
          b.HL @hl, nil, "20", "1"
        b.NM1 "85", "2", @sender.mmis_enrollment_name, nil, nil, nil, nil, 'XX', @sender.npi
          b.N3  @sender.address_1
          b.N4  @sender.city, @sender.state, @sender.zip.delete('^0-9')
          b.REF "EI", @sender.ein

      patients.each do |patient|
        # skip the patient if there are no QA that can be sent
        patient_qa = patient.qualifying_activities.unsubmitted.payable.
          where(
            hqa_t[:date_of_activity].lteq(max_date).
            and(hqa_t[:date_of_activity].gteq(start_date))
          )
        next unless patient_qa.map(&:procedure_code).map(&:present?).any?

        @hl += 1
        pr = patient.patient_referral

        city_state_zip = [pr&.address_city, pr&.address_state, pr&.address_zip&.delete('^0-9')]
        if city_state_zip.reject(&:blank?).count != 3
          city_state_zip = [@sender.city, @sender.state, @sender.zip.delete('^0-9')]
        end
        b.HL @hl, '1', '22', '0'
          b.SBR 'P', '18', nil, nil, nil, nil, nil, nil, 'MC'
          b.NM1 'IL', '1', pr.last_name, pr.first_name, nil, nil, nil, 'MI', pr.medicaid_id
          b.N3((pr.address_line_1.presence || @sender.address_1)&.gsub("\n", ' '))
          b.N4 *city_state_zip
          b.DMG 'D8', pr.birthdate&.strftime('%Y%m%d'), pr.gender.presence || 'U'
          b.NM1 'PR', '2', @sender.receiver_name, nil, nil, nil, nil, 'PI', @sender.receiver_id
          valid_qa = patient_qa.where(hqa_t[:date_of_activity].lteq(max_date)).
            select{|m| m.procedure_code.present?}
          # batch services by month
          valid_qa.group_by{|qa| qa.date_of_activity.strftime('%Y%m')}.each do |group, qas|
            # puts "QA Count: #{qas.count} in #{group} for patient: #{patient.id}"

            # never put more than 20 services in any given claim
            qas.each_slice(20) do |qa_batch|
              @lx = 0 # Reset LX for batch
              b.CLM pr.id, '0', nil, nil, b.composite('11', 'B', '1'), 'Y', 'A', 'Y', 'Y'
              b.HI b.composite('ABK', 'Z029')
                qa_batch.each do |qa|
                  @lx += 1
                  b.LX @lx
                  b.SV1 b.composite('HC', *qa.procedure_code.split(component_element_separator), *qa.modifiers), '0', 'UN', '1', nil, nil, b.composite('1')
                  b.DTP '472', 'D8', qa.date_of_activity.strftime('%Y%m%d')
                end
            end
          end
      end
      m = b.machine
      st = m
      while st.segment.fetch.node.id != :ST
        st = st.parent.fetch
      end

      # ST line should be the second line in the file
      b.SE 2 + m.distance(st).fetch, id.to_s.rjust(4, '0')
      b.GE '1', @group_control_number
      b.IEA '1', @isa_control_number.to_s.rjust(9, '0')

      @edi_builder = b
    end

    def convert_claims_to_text
      file = ''
      @edi_builder.machine.zipper.tap do |z|
        separators = Stupidedi::Reader::Separators.build(
          segment: "~\n",
          element: "*",
          component: component_element_separator,
          repetition:  repetition_separator
        )
        w = Stupidedi::Writer::Default.new(z.root, separators)
        file = w.write().upcase
      end
      return file
    end

    def pid_sl_from_claims_file
      pid_sl = ''
      parsed_claims_file.first.tap do |m|
        el(m, 6){|e| pid_sl = e}
      end
      return pid_sl
    end

    def parsed_claims_file
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Builder::StateMachine.build(config)
      parser, result = parser.read(Stupidedi::Reader.build(claims_file))
      if result.fatal?
        result.explain{|reason| raise reason + " at #{result.position.inspect}" }
      end
      return parser
    end

    # Helper function: fetch an element from the current segment
    def el(m, *ns, &block)
      if Stupidedi::Either === m
        m.tap{|m| el(m, *ns, &block) }
      else
        yield(*ns.map{|n| m.elementn(n).map(&:value).fetch })
      end
    end


    def start_report
      update(started_at: Time.now)
    end

    def complete_report
      assign_attributes(
        completed_at: Time.now,
        max_isa_control_number: @isa_control_number,
        max_group_control_number: @group_control_number,
        max_st_number: @st_control_number
      )
      save!
    end

    def start_date
      max_date.beginning_of_month
    end

    def attach_quailifying_activities_to_report
      Health::QualifyingActivity.unsubmitted.
        in_range(start_date..max_date).
        update_all(claim_id: id)
    end

    def mark_qualifying_activites_as_submitted
      qualifying_activities.payable.update_all(claim_submitted_on: Date.current)
    end

    def status
      if error
        error
      elsif completed_at.present?
        'Complete'
      elsif started_at.blank?
        'Queued'
      else
        "Running since #{started_at}"
      end
    end

    def implementation_convention_reference_number
      '005010X222A1'
    end

    def repetition_separator
      '^'
    end

    def interchange_usage_indicator
      return 'T' if test_file
      return 'P' if Rails.env.production?

      'T'
    end

    def component_element_separator
      '>'
    end

    def self.next_isa_control_number
      current_max = maximum(:max_isa_control_number) || 10
      current_max += 1
    end

    def self.next_group_control_number
      current_max = maximum(:max_group_control_number) || 1010
      current_max += 1
    end

    def self.next_st_control_number
      current_max = maximum(:max_st_number) || 1010
      current_max += 1
    end

  end
end
