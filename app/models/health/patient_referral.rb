module Health
  class PatientReferral < HealthBase

    scope :assigned, -> {where.not(agency_id: nil)}
    scope :unassigned, -> {where(agency_id: nil)}

    # TODO: What needs to be validated here?
    validates_presence_of :first_name, :last_name, :birthdate, :ssn, :medicaid_id
    validates_size_of :ssn, is: 9

    has_many :relationships, class_name: 'Health::AgencyPatientReferral', dependent: :destroy
    belongs_to :assigned_agency, class_name: 'Health::Agency', foreign_key: 'agency_id'

    accepts_nested_attributes_for :relationships

    def relationship_to(agency)
      relationships.where(agency_id: agency).last
    end

    def assigned?
      agency_id.present?
    end

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

    def display_claimed_by_other(agency)
      cb = display_claimed_by
      other_size = cb.select{|c| c != 'Unclaimed'}.size
      if other_size > 0
        if cb.include?(agency.name)
          other_size = other_size - 1
        end
        if other_size > 0
          agency = 'Agency'.pluralize(other_size)
          "#{other_size} Other #{agency}"
        end
      else
        'Unclaimed'
      end
    end

    def display_claimed_by
      claimed = relationships.claimed
      if claimed.any?
        claimed.map{|r| r.agency.name}
      else
        ['Unclaimed']
      end
    end

    def display_unclaimed_by
      unclaimed = relationships.unclaimed
      unclaimed.map{|r| r.agency.name}
    end

    def self.text_search(text)
      return none unless text.present?
      text.strip!
      pr_t = arel_table
      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = pr_t[:first_name].lower.matches("#{first.downcase}%")
          .and(pr_t[:last_name].lower.matches("#{last.downcase}%"))
        # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = pr_t[:first_name].lower.matches("#{first.downcase}%")
          .and(pr_t[:last_name].lower.matches("#{last.downcase}%"))
      else
        query = "%#{text.downcase}%"
        
        where = pr_t[:last_name].lower.matches(query).
          or(pr_t[:first_name].lower.matches(query)).
          or(pr_t[:medicaid_id].lower.matches(query))
      end
      where(where)
    end

  end
end