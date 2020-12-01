require 'csv'
module ClaimsReporting
  class CcsLookup < HealthBase
    def self.load_csv(file, effective_range)
      data = []
      CSV.foreach(file, 'r', headers: true, quote_char: '"', skip_lines: /Valid codes are in ranges/) do |row|
        range = row['Code Range'].gsub("'", '').split('-')
        data << {
          hcpcs_start: range.first,
          hcpcs_end: range.last,
          ccs_id: row['CCS'],
          ccs_lable: row['CCS Label'],
          effective_start: effective_range&.min,
          effective_end: effective_range&.max,
        }
        puts data.last.inspect
      end
    end
  end
end
