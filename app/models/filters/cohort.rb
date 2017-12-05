# This filter keeps track of how we filter by various standard cohorts
# 1. Veteran
# 2. Family
# 3. Individual
# 4. Unaccompanied Youth (18-24)
# 5. Unaccompanied Children (< 18)
module Filters
  class Cohort < ::ModelForm
    attribute :veteran, Boolean, default: false
    attribute :family, Boolean, default: false

    def veteran_options
      {
        'Veteran' => true,
        'Non-Veteran' => false,
      }
    end

    def family_options
      {
        'Family' => :family,
        'Individual' => :individual,
      }
    end

  end
end