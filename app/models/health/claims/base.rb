###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - abstract_class contains no PHI
require 'roo'
module Health::Claims
  class Base < HealthBase
    self.abstract_class = true
    include TsqlImport
    attr_accessor :sheet

    def initialize(sheet)
      @sheet = sheet
    end

    def column_headers
      raise 'Implement in Sub-class'
    end

    def import!
      validate_headers
      clean_sheet = clean_rows(sheet.drop(1))
      transaction do
        self.class.delete_all
        insert_batch( self.class, column_headers.keys, clean_sheet)
      end
    end

    # allow for cleaning of data in sub-classes, default to cleaning up divide by 0
    def clean_rows(dirty)
      dirty.map do |row|
        row.map do |value|
          if value == "#DIV/0!"
            nil
          else
            value
          end
        end
      end
    end

    def validate_headers
      sheet_headers = sheet.first.map(&:downcase)
      db_headers = column_headers.values.map(&:downcase)
      raise "Unexpected headers in: #{self.class.name} \n #{sheet_headers.inspect} \n Looking for: \n #{db_headers.inspect}" if sheet_headers.sort != db_headers.sort
    end

    def self.known_sub_classes
      [
        Health::Claims::AmountPaid,
        Health::Claims::ClaimsVolume,
        Health::Claims::EdNyuSeverity,
        Health::Claims::Roster,
        Health::Claims::TopConditions,
        Health::Claims::TopIpConditions,
        Health::Claims::TopProviders,
      ]
    end
  end
end
