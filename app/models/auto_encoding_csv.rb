require 'csv'
require 'charlock_holmes'

class AutoEncodingCsv < CSV
  UTF8_BOM = "\xEF\xBB\xBF".b.freeze
  UTF16LE_BOM = "\xFF\xFE".b.freeze
  UTF16BE_BOM = "\xFE\xFF".b.freeze

  class << self
    def open(filename, mode="r", **options)
      options ||= {}

      if mode.start_with?('r') && options[:encoding].nil?
        # a Unicode BOM is a strong signal
        magic = File.read(filename, 3, mode: 'rb')
        guessed_encoding = if magic.first(3) == UTF8_BOM
           'bom|UTF-8'
        elsif magic.first(2) == UTF16LE_BOM
           'bom|UTF-16LE'
        elsif magic.first(2) == UTF16BE_BOM
           'bom|UTF-16BE'
        end

        # no BOM we have to try for a statistical match
        unless guessed_encoding
          File.open(filename, mode: 'rb') do |io|
            res = CharlockHolmes::EncodingDetector.detect(io.read)
            guessed_encoding = res[:ruby_encoding] if res
          end
        end

        options[:encoding] = guessed_encoding if guessed_encoding

        $stdout.puts "#{filename} #{options}"
      end

      super filename, mode, **options
    end
  end
end
