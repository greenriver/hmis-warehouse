module Health
  class Claim < HealthBase
    acts_as_paranoid
    has_many :qualifying_activities

    scope :visible_by?, -> (user) do
      if user.can_administer_health?
        all
      else
        none
      end
    end

    def submitted?
      submitted_at.present?
    end

    def patients
      start_date = max_date - 6.months
      Health::Patient.joins(:patient_referral).
        with_unsubmitted_qualifying_activities_within(start_date..max_date)
    end

    def run!
      start_report
      @isa_control_number = self.class.next_isa_control_number
      @group_control_number = self.class.next_group_control_number
      @st_control_number = self.class.next_st_control_number
      @hl = 0
      @sender = Health::Cp.sender.first
      qualifying_activity_ids = []
      self.claims_file = "#{isa_line}\n"
      self.claims_file += "#{gs_line}\n"
      self.claims_file += "#{st_line}\n"
      self.claims_file += "#{bht_line}\n"
      self.claims_file += "#{submitter_line}\n"
      self.claims_file += "#{submitter_edi_contact_line}\n"
      self.claims_file += "#{receiver_line}\n"
      self.claims_file += "#{open_2005_loop_line}\n"
      self.claims_file += "#{billing_2010_aa_line}\n"

      patients.each do |patient|
        @lx = 0
        self.claims_file += "#{patient_header(patient)}\n"
        self.claims_file += "#{patient_payer(patient)}\n"
        self.claims_file += "#{patient_claims_header(patient)}\n"
        self.claims_file += "#{patient_diagnosis(patient)}\n"
        patient.qualifying_activities.unsubmitted.submittable.
          select{|m| m.procedure_code.present?}.each do |qa|
            qualifying_activity_ids << qa.id
            self.claims_file += "#{claim_lines(qa)}\n"
        end
      end
      self.claims_file += "#{trailer}\n"
      self.claims_file.upcase!

      attach_quailifying_activities_to_report(qualifying_activity_ids)
      complete_report
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

    def attach_quailifying_activities_to_report qualifying_activity_ids
      Health::QualifyingActivity.where(id: qualifying_activity_ids).update_all(claim_id: id)
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

    def isa_line
      line = "ISA*00*#{' ' * 10}*00*#{' ' * 10}*ZZ*"
      line += "#{@sender.pid}#{@sender.sl}".ljust(15)
      line += '*ZZ*'
      line += "#{@sender.receiver_id}".ljust(15)
      line += "*#{created_at.strftime('%y%m%d*%H%M')}"
      line += "*#{repetition_separator}*00501*"
      line += "#{@isa_control_number}".rjust(9, '0')
      line += "*0*#{interchange_usage_indicator}*#{component_element_separator}~"
    end

    def gs_line
      line = 'GS*HC*'
      line += "#{@sender.pid}#{@sender.sl}"
      line += "*#{@sender.receiver_id}"
      line += "*#{created_at.strftime('%Y%m%d*%H%M')}"
      line += "*#{@group_control_number}"
      line += "*X*#{implementation_convention_reference_number}~"
    end

    def st_line
      line = 'ST*837*'
      line += id.to_s.rjust(4, '0')
      line += "*#{implementation_convention_reference_number}~"
    end

    def bht_line
      line = 'BHT*0019*'
      line += '00' # transaction set purpose code, 18 for resubmit
      line += '*'
      line += id.to_s.rjust(4, '0')
      line += "*#{created_at.strftime('%Y%m%d*%H%M')}"
      line += '*CH~'
    end

    def submitter_line
      line = 'NM1*41*2'
      line += "*#{@sender.mmis_enrollment_name}#{'*' * 5}46*"
      line += "#{@sender.pid}#{@sender.sl}"
      line += '~'
    end

    def submitter_edi_contact_line
      line = 'PER*IC'
      line += "*#{@sender.key_contact_first_name} #{@sender.key_contact_last_name}"
      line += "*TE*#{@sender.key_contact_phone.delete('^0-9')}~"
    end

    def receiver_line
      line = 'NM1*40*2'
      line += "*#{@sender.receiver_name}#{'*' * 5}46"
      line += "*#{@sender.receiver_id}"
      line += '~'
    end

    def open_2005_loop_line
      @hl += 1
      line = "HL*#{@hl}**20*1~"
    end

    def billing_2010_aa_line
      line = "NM1*85*2"
      line += "*#{@sender.mmis_enrollment_name}#{'*' * 5}XX*#{@sender.npi}~\n"
      line += "N3*#{@sender.address_1}~\n"
      line += "N4*#{@sender.city}*#{@sender.state}*#{@sender.zip.delete('^0-9')}~\n"
      line += "REF*EI*#{@sender.ein}~"
    end

    def patient_header patient
      @hl += 1
      pr = patient.patient_referral
      line = "HL*#{@hl}*1*22*0~\n"
      line += "SBR*P*18#{'*' * 7}MC~\n"
      line += "NM1*IL*1*#{pr.last_name}*#{pr.first_name}#{'*' * 4}MI*#{pr.medicaid_id}~\n"
      line += "N3*#{pr.address_line_1 || @sender.address_1}~\n"
      line += "N4*#{pr.address_city || @sender.city}*#{pr.address_state || @sender.state}*#{pr.address_zip || @sender.zip}~\n"
      line += "DMG*D8*#{pr.birthdate&.strftime('%Y%m%d')}*#{pr.gender || 'U'}~"
    end

    def patient_payer patient
      pr = patient.patient_referral
      line = "NM1*PR*2"
      line += "*#{@sender.receiver_name}#{'*' * 5}PI"
      line += "*#{@sender.receiver_id}"
      line += '~'
    end

    def patient_claims_header patient
      pr = patient.patient_referral
      line = "CLM*#{pr.id}*0***11"
      line += "#{component_element_separator}B#{component_element_separator}1*Y*A*Y*Y~"
    end

    def patient_diagnosis patient
      pr = patient.patient_referral
      line = "HI*ABK#{component_element_separator}Z029~"
    end

    def claim_lines qa
      @lx += 1
      line = "LX*#{@lx}~\n"
      line += "SV1*HC#{component_element_separator}"
      line += "#{qa.procedure_code}#{component_element_separator}#{qa.modifiers.join(component_element_separator).to_s}"
      line += "*0*UN*1***1~\n"
      line += "DTP*472*D8*#{qa.date_of_activity.strftime('%Y%m%d')}~"
    end

    def trailer
      lines = self.claims_file.lines.count - 1
      line = "SE*#{lines}*#{id.to_s.rjust(4, '0')}~\n"
      line += "GE*1*#{@group_control_number}~\n"
      line += "IEA*1*"
      line += "#{@isa_control_number}".rjust(9, '0')
      line += '~'
    end

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