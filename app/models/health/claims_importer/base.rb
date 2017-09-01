require 'roo'
module Health::ClaimsImporter
  class Base < HealthBase
    include TsqlImport
    attr_accessor :sheet
    
    def initialize(sheet)
      @sheet = sheet
    end

    def column_headers
      raise 'Implement in Sub-class'
    end

    def run!
      validate_headers
      clean_sheet = clean_rows(sheet.drop(1))
      transaction do
        self.class.delete_all
        insert_batch( self.class, column_headers.keys, clean_sheet)
      end
    end

    # allow for cleaning of data in sub-classes, default to no-op
    def clean_rows(dirty)
      dirty
    end

    def validate_headers
      raise 'Unexpected headers' if sheet.first != column_headers.values
    end
  end
end