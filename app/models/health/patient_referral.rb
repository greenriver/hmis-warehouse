module Health
  class PatientReferral < HealthBase
    # TODO: What needs to be validated here?

    def name
      "#{first_name} #{last_name}"
    end

    def age
      if birthdate.present?
        ((Time.now - birthdate.to_time)/1.year.seconds).floor
      else
        'Unknown'
      end
    end

    def display_ssn
      if ssn
        "XXX-XX-#{ssn.chars.last(4).join}"
      else
        'Unknown'
      end
    end

    def claimed_by
      # TODO
      ['Unclaimed']
    end

  end
end