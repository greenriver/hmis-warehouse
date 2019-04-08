module Cas
  class Tag < CasBase
    acts_as_paranoid

    def self.available_tags
      all
    end
  end
end