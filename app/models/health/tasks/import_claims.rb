###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
module Health::Tasks
  class ImportClaims

    attr_accessor :claims_file_path, :claims_file
    def initialize(claims_file_path: 'var/health/claims_metrics_sample.xlsx')
      @claims_file_path = claims_file_path
    end

    def run!
      load_file
      claims_file.each_with_pagename do |name, sheet|
        case name
        when 'Claim_Volume_Location_Month'
          process_claim_volume(sheet)
        when 'Amount_Paid_Location_Month'
          process_amount_paid(sheet)
        when 'Top_Providers'
          process_top_providers(sheet)
        when 'Top_Conditions'
          process_top_conditions(sheet)
        when 'Top_IP_Conditions'
          process_top_ip_conditions(sheet)
        when 'ED_NYU_Severity'
          process_ed_nyu_severity(sheet)
        when 'Roster'
          process_roster(sheet)
        else
          puts "Skipping unimplemented tab: #{name}"
        end
      end
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
