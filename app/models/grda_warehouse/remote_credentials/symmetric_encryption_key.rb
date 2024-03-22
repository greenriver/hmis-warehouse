###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteCredentials::SymmetricEncryptionKey < GrdaWarehouse::RemoteCredential
    # FIXME: we have a peculiar convention of repurposing the attributes of the remote credential class. Needs refactor
    alias_attribute :algorithm, :username
    alias_attribute :key_hex, :encrypted_password

    # decrypt combined_hex using secret key_hex. openssl lib has an unusual api
    # @param [String] combined_hex is the 16 byte IV concatenated with the ciphertext
    def decrypt(combined_hex)
      return unless key_hex && combined_hex && combined_hex.is_a?(String) && combined_hex.length > 32

      cipher = OpenSSL::Cipher.new(algorithm)
      cipher.decrypt
      cipher.key = [key_hex].pack('H*') # Convert key hex to binary

      # The IV is the first 32 hex characters (16 bytes), cipher text follows
      iv_hex = combined_hex[0...32] # Extract the IV from the first 32 hex chars
      encrypted_data_hex = combined_hex[32..] # The rest is the encrypted data

      cipher.iv = [iv_hex].pack('H*') # Convert IV hex to binary

      encrypted_data = [encrypted_data_hex].pack('H*') # Convert encrypted data hex to binary
      cipher.update(encrypted_data) + cipher.final
    end
  end
end
