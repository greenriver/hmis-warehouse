###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HomelessSummaryReport
  class Client < GrdaWarehouseBase
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :report

    # Create a scope for each report variant
    HOUSEHOLD_VARIANTS = [
      :all_persons,
      :without_children,
      :with_children,
      :only_children,
      :without_children_and_fifty_five_plus,
      :adults_with_children_where_parenting_adult_18_to_24,
    ].freeze
    DEMOGRAPHIC_VARIANTS = [
      :all,
      :non_hispanic_latino,
      :hispanic_latino,
      :black_african_american,
      :asian,
      :american_indian_alaskan_native,
      :native_hawaiian_other_pacific_islander,
      :white,
      :white_non_hispanic_latino,
      :multi_racial,
      :race_none,
      :b_n_h_l,
      :a_n_h_l,
      :n_n_h_l,
      :h_n_h_l,
      :fleeing_dv,
      :veteran,
      :has_disability,
      :has_rrh_move_in_date,
      :has_psh_move_in_date,
      :first_time_homeless,
      :returned_to_homelessness_from_permanent_destination,
    ].freeze

    HOUSEHOLD_VARIANTS.each do |variant_slug|
      DEMOGRAPHIC_VARIANTS.each do |sub_variant_slug|
        variant = "spm_#{variant_slug}__#{sub_variant_slug}".to_sym
        scope variant, -> { where(arel_table[variant[0..62]].gt(0)) }
        alias_attribute(variant, variant[0..62]) # Some fields are too long for postgres
      end
    end

    scope :spm_m1a_es_sh_days, -> { where(arel_table[:spm_m1a_es_sh_days].gt(0)) }
    scope :spm_m1a_es_sh_th_days, -> { where(arel_table[:spm_m1a_es_sh_th_days].gt(0)) }
    scope :spm_m1b_es_sh_ph_days, -> { where(arel_table[:spm_m1b_es_sh_ph_days].gt(0)) }
    scope :spm_m1b_es_sh_th_ph_days, -> { where(arel_table[:spm_m1b_es_sh_th_ph_days].gt(0)) }

    scope :spm_m2_reentry_days, -> { where(arel_table[:spm_m2_reentry_days].gteq(0)) }
    scope :spm_m2_reentry_0_to_180_days, -> { where(arel_table[:spm_m2_reentry_days].between(1..180)) }
    scope :spm_m2_reentry_181_to_365_days, -> { where(arel_table[:spm_m2_reentry_days].between(181..365)) }
    scope :spm_m2_reentry_366_to_730_days, -> { where(arel_table[:spm_m2_reentry_days].between(366..730)) }

    scope :spm_m7a1_destination, -> { where(arel_table[:spm_m7a1_destination].gt(0)) }
    scope :spm_m7b1_destination, -> { where(arel_table[:spm_m7b1_destination].gt(0)) }
    scope :spm_m7b2_destination, -> { where(arel_table[:spm_m7b2_destination].not_eq(nil)) } # include 0 which represents remained housed
    scope :spm_m7a1_c2, -> { where(arel_table[:spm_m7a1_c2].eq(true)) }
    scope :spm_m7a1_c3, -> { where(arel_table[:spm_m7a1_c3].eq(true)) }
    scope :spm_m7a1_c4, -> { where(arel_table[:spm_m7a1_c4].eq(true)) }
    scope :spm_m7b1_c2, -> { where(arel_table[:spm_m7b1_c2].eq(true)) }
    scope :spm_m7b1_c3, -> { where(arel_table[:spm_m7b1_c3].eq(true)) }
    scope :spm_m7b2_c2, -> { where(arel_table[:spm_m7b2_c2].eq(true)) }
    scope :spm_m7b2_c3, -> { where(arel_table[:spm_m7b2_c3].eq(true)) }

    scope :spm_exited_from_homeless_system, -> { where(arel_table[:spm_exited_from_homeless_system].eq(true)) }

    # return a new client with all the SPM fields defaulted to 0 so we don't have to look for nils later
    def self.new_with_default_values
      new.tap do |defaulted|
        HOUSEHOLD_VARIANTS.each do |household_category|
          DEMOGRAPHIC_VARIANTS.each do |demographic_category|
            defaulted["spm_#{household_category}__#{demographic_category}"[0..62]] = 0
          end
        end
      end
    end
  end
end
