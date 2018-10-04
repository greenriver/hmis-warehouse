require "stupidedi"
module Health
  class Claim < HealthBase
    include ArelHelper
    acts_as_paranoid
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
      mark_qualifying_activites_as_submitted
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
          where(hqa_t[:date_of_activity].lteq(max_date))
        next unless patient_qa.map(&:procedure_code).map(&:present?).any?


        @lx = 0
        @hl += 1
        pr = patient.patient_referral

        city_state_zip = [pr.address_city, pr.address_state, pr.address_zip]
        if city_state_zip.compact.empty?
          city_state_zip = [@sender.city, @sender.state, @sender.zip]
        end
        b.HL @hl, '1', '22', '0'
          b.SBR 'P', '18', nil, nil, nil, nil, nil, nil, 'MC'
          b.NM1 'IL', '1', pr.last_name, pr.first_name, nil, nil, nil, 'MI', pr.medicaid_id
          b.N3 pr.address_line_1.presence || @sender.address_1
          b.N4 city_state_zip.join(', ')
          b.DMG 'D8', pr.birthdate&.strftime('%Y%m%d'), pr.gender || 'U'
          b.NM1 'PR', '2', @sender.receiver_name, nil, nil, nil, nil, 'PI', @sender.receiver_id
          valid_qa = patient_qa.where(hqa_t[:date_of_activity].lteq(max_date)).
            select{|m| m.procedure_code.present?}
          # batch services by month
          valid_qa.group_by{|qa| qa.date_of_activity.strftime('%Y%m')}.each do |group, qas|
            # puts "QA Count: #{qas.count} in #{group} for patient: #{patient.id}"

            # never put more than 20 services in any given claim
            qas.each_slice(20) do |qa_batch|
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

      b.SE 1 + m.distance(st).fetch, id.to_s.rjust(4, '0')
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
      max_date - 6.months
    end

    def attach_quailifying_activities_to_report
      Health::QualifyingActivity.unsubmitted.
        in_range(start_date..max_date).
        update_all(claim_id: id)
    end

    def mark_qualifying_activites_as_submitted
      qualifying_activities.payable.update_all(claim_submitted_on: Date.today)
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

    # def isa_line
    #   line = "ISA*00*#{' ' * 10}*00*#{' ' * 10}*ZZ*"
    #   line += "#{@sender.pid}#{@sender.sl}".ljust(15)
    #   line += '*ZZ*'
    #   line += "#{@sender.receiver_id}".ljust(15)
    #   line += "*#{created_at.strftime('%y%m%d*%H%M')}"
    #   line += "*#{repetition_separator}*00501*"
    #   line += "#{@isa_control_number}".rjust(9, '0')
    #   line += "*0*#{interchange_usage_indicator}*#{component_element_separator}~"
    # end

    # def gs_line
    #   line = 'GS*HC*'
    #   line += "#{@sender.pid}#{@sender.sl}"
    #   line += "*#{@sender.receiver_id}"
    #   line += "*#{created_at.strftime('%Y%m%d*%H%M')}"
    #   line += "*#{@group_control_number}"
    #   line += "*X*#{implementation_convention_reference_number}~"
    # end

    # def st_line
    #   line = 'ST*837*'
    #   line += id.to_s.rjust(4, '0')
    #   line += "*#{implementation_convention_reference_number}~"
    # end

    # def bht_line
    #   line = 'BHT*0019*'
    #   line += '00' # transaction set purpose code, 18 for resubmit
    #   line += '*'
    #   line += id.to_s.rjust(4, '0')
    #   line += "*#{created_at.strftime('%Y%m%d*%H%M')}"
    #   line += '*CH~'
    # end

    # def submitter_line
    #   line = 'NM1*41*2'
    #   line += "*#{@sender.mmis_enrollment_name}#{'*' * 5}46*"
    #   line += "#{@sender.pid}#{@sender.sl}"
    #   line += '~'
    # end

    # def submitter_edi_contact_line
    #   line = 'PER*IC'
    #   line += "*#{@sender.key_contact_first_name} #{@sender.key_contact_last_name}"
    #   line += "*TE*#{@sender.key_contact_phone.delete('^0-9')}~"
    # end

    # def receiver_line
    #   line = 'NM1*40*2'
    #   line += "*#{@sender.receiver_name}#{'*' * 5}46"
    #   line += "*#{@sender.receiver_id}"
    #   line += '~'
    # end

    # def open_2005_loop_line
    #   @hl += 1
    #   line = "HL*#{@hl}**20*1~"
    # end

    # def billing_2010_aa_line
    #   line = "NM1*85*2"
    #   line += "*#{@sender.mmis_enrollment_name}#{'*' * 5}XX*#{@sender.npi}~\n"
    #   line += "N3*#{@sender.address_1}~\n"
    #   line += "N4*#{@sender.city}*#{@sender.state}*#{@sender.zip.delete('^0-9')}~\n"
    #   line += "REF*EI*#{@sender.ein}~"
    # end

    # def patient_header patient
    #   @hl += 1
    #   pr = patient.patient_referral
    #   line = "HL*#{@hl}*1*22*0~\n"
    #   line += "SBR*P*18#{'*' * 7}MC~\n"
    #   line += "NM1*IL*1*#{pr.last_name}*#{pr.first_name}#{'*' * 4}MI*#{pr.medicaid_id}~\n"
    #   line += "N3*#{pr.address_line_1 || @sender.address_1}~\n"
    #   line += "N4*#{pr.address_city || @sender.city}*#{pr.address_state || @sender.state}*#{pr.address_zip || @sender.zip}~\n"
    #   line += "DMG*D8*#{pr.birthdate&.strftime('%Y%m%d')}*#{pr.gender || 'U'}~"
    # end

    # def patient_payer patient
    #   pr = patient.patient_referral
    #   line = "NM1*PR*2"
    #   line += "*#{@sender.receiver_name}#{'*' * 5}PI"
    #   line += "*#{@sender.receiver_id}"
    #   line += '~'
    # end

    # def patient_claims_header patient
    #   pr = patient.patient_referral
    #   line = "CLM*#{pr.id}*0***11"
    #   line += "#{component_element_separator}B#{component_element_separator}1*Y*A*Y*Y~"
    # end

    # def patient_diagnosis patient
    #   pr = patient.patient_referral
    #   line = "HI*ABK#{component_element_separator}Z029~"
    # end

    # def claim_lines qa
    #   @lx += 1
    #   line = "LX*#{@lx}~\n"
    #   line += "SV1*HC#{component_element_separator}"
    #   line += "#{qa.procedure_code}#{component_element_separator}#{qa.modifiers.join(component_element_separator).to_s}"
    #   line += "*0*UN*1***1~\n"
    #   line += "DTP*472*D8*#{qa.date_of_activity.strftime('%Y%m%d')}~"
    # end

    # def trailer
    #   lines = self.claims_file.lines.count - 1
    #   line = "SE*#{lines}*#{id.to_s.rjust(4, '0')}~\n"
    #   line += "GE*1*#{@group_control_number}~\n"
    #   line += "IEA*1*"
    #   line += "#{@isa_control_number}".rjust(9, '0')
    #   line += '~'
    # end

    def implementation_convention_reference_number
      '005010X222A1'
    end

    def repetition_separator
      '^'
    end

    def interchange_usage_indicator
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