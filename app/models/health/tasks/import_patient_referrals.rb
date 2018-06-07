require 'roo'
module Health::Tasks
  class ImportPatientReferrals

    attr_accessor :directory, :referrals_file 
    def initialize(directory: 'var/health/referrals')
      @directory = directory
    end

    def import!
      return unless unprocessed?
      
    end

    # Are there any ASSIGNMENT_FULL files we have not yet processed?
    def unprocessed?
      
    end


    def load_file
      @claims_file = Roo::Spreadsheet.open(claims_file_path)
    end

    def process_claim_volume(sheet)
      Health::Claims::ClaimsVolume.new(sheet).import!
    end

    def process_amount_paid(sheet)
      Health::Claims::AmountPaid.new(sheet).import!
    end

    def process_top_providers(sheet)
      Health::Claims::TopProviders.new(sheet).import!
    end

    def process_top_conditions(sheet)
      Health::Claims::TopConditions.new(sheet).import!
    end

    def process_top_ip_conditions(sheet)
      Health::Claims::TopIpConditions.new(sheet).import!
    end

    def process_ed_nyu_severity(sheet)
      Health::Claims::EdNyuSeverity.new(sheet).import!
    end

    def process_roster(sheet)
      Health::Claims::Roster.new(sheet).import!
    end
  end
end