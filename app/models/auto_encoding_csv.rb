require 'csv'
require 'charlock_holmes'

class AutoEncodingCsv < CSV
  class << self
    def open(filename, mode="r", **options)
      options ||= {}

      if mode.start_with?('r') && options[:encoding].nil?
        detection_data = File.read(filename)
        res = CharlockHolmes::EncodingDetector.detect(detection_data)
        if res && res[:ruby_encoding]
          guessed_encoding = res[:ruby_encoding]
          if ['UTF-8','UTF-16LE','UTF-16BE','UTF-16'].include?(guessed_encoding.upcase)
            bom_found = detection_data.start_with? "\ufeff"
            guessed_encoding = "bom|#{guessed_encoding}" if bom_found
          end
          #data.set_encoding guessed_encoding if data.external_encoding != guessed_encoding
        end
        options[:encoding] = guessed_encoding
      end

      super(filename, mode, **options)
    end
  end
end
