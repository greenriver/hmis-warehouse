Rails.logger.debug "Running initializer in #{__FILE__}"

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProtectedId
  PROTECT_IDS = ENV['PROTECTED_IDS'].present? && ENV['PROTECTED_IDS'] == 'true'
  INITIAL_DELIMITER = '=='

  module Encoder
    def encode(id)
      return id.to_s unless PROTECT_IDS

      day_stamp = Date.today.to_time.to_i / (60 * 60 * 24) # Seconds in a day
      obfuscate(id, day_stamp)
    end
    module_function :encode

    def encoded?(id)
      false if id.blank?
      # confirm that the string is encoded
      id.starts_with?(INITIAL_DELIMITER)
    end
    module_function :encoded?

    def decode(encoded)
      encoded.map { |part| decode(part) }.compact if encoded.is_a?(Enumerable)
      return encoded unless encoded?(encoded)

      id, _day_stamp = deobfuscate(encoded)
      # TODO expire protected ids
      id
    end
    module_function :decode

    KEY = ENV.fetch('PROTECTED_ID_KEY', ENV.fetch('FQDN', 'rX9BDyW0')[0..7]) # Fall back to the FQDN or a fixed string

    def obfuscate(id, day_stamp)
      # a composed id is 64 bits, the upper 32 has the id, the lower 32, the days since the epoch
      composed = (id << 32) + day_stamp
      encrypted = Encryptor.encrypt(
        value: composed.to_s(16), # encrypt requires a string, so convert the composed id into hex
        algorithm: 'des-ecb', # Weak algorithm to limit size of ids
        insecure_mode: true, # No IV
        key: KEY,
      )

      INITIAL_DELIMITER + Base64.encode64(encrypted).delete_suffix("\n") # Remove the trailing newline from the encoding
    end
    module_function :obfuscate

    def deobfuscate(slug)
      encrypted = Base64.decode64(slug.delete_prefix(INITIAL_DELIMITER))
      composed = Encryptor.decrypt(
        value: encrypted,
        algorithm: 'des-ecb',
        insecure_mode: true,
        key: KEY,
      ).to_i(16)

      id_part = composed >> 32
      day_stamp = composed & (2**32 - 1)

      [id_part, day_stamp]
    end
    module_function :deobfuscate
  end

  module Labeler
    include Encoder

    def to_param
      encode(id)
    end
  end

  module Finder
    include Encoder

    def find(*args, &block)
      id = decode(args.first)
      super(id, *args[1..-1], &block)
    end
  end
end

ActiveRecord::Base.send(:include, ProtectedId::Labeler)
#ActiveRecord::Base.extend(ProtectedId::Finder)
#ActiveRecord::Relation.send(:include, ProtectedId::Finder)
