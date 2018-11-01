module Glacier
  class Vault < ActiveRecord::Base
    has_many :archives, foreign_key: 'glacier_vault_id'
  end
end
