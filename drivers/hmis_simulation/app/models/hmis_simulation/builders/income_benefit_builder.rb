###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates Hmis::Hud::IncomeBenefit records.
    # Called at enrollment entry (stage 1), annual assessment (stage 5), and exit (stage 3).
    #
    # Config keys (income_at_entry section from simulation config):
    #   no_income_probability: float — probability client has no income
    #   sources: hash of source_key => weight (e.g. { "ssi" => 0.2, "earned" => 0.1 })
    class IncomeBenefitBuilder < BaseBuilder
      DATA_COLLECTION_STAGES = { entry: 1, update: 2, exit: 3, annual: 5 }.freeze

      # Maps config source keys to HUD field names and typical monthly amounts
      INCOME_SOURCES = {
        'ssi' => { field: :SSI, amount_field: :SSIAmount, typical_amount: 943 },
        'ssdi' => { field: :SSDI, amount_field: :SSDIAmount, typical_amount: 1400 },
        'earned' => { field: :Earned, amount_field: :EarnedAmount, typical_amount: 1100 },
        'ga' => { field: :GA, amount_field: :GAAmount, typical_amount: 350 },
        'tanf' => { field: :TANF, amount_field: :TANFAmount, typical_amount: 500 },
        'unemployment' => { field: :Unemployment, amount_field: :UnemploymentAmount, typical_amount: 800 },
      }.freeze

      def initialize(enrollment:, date:, stage:, income_config:, data_source:, user_id:, rng_seed:)
        super(data_source: data_source, user_id: user_id)
        @enrollment    = enrollment
        @date          = date
        @stage         = stage
        @income_cfg    = (income_config || {}).deep_stringify_keys
        @rng_seed      = rng_seed
      end

      def build!
        dcs = DATA_COLLECTION_STAGES.fetch(@stage, 1)
        attrs = build_income_attributes

        Hmis::Hud::IncomeBenefit.create!(
          **audit_attrs(@date),
          IncomeBenefitsID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          InformationDate: @date,
          DataCollectionStage: dcs,
          **attrs,
        )
      end

      private

      def build_income_attributes
        no_income_prob = @income_cfg['no_income_probability'].to_f
        return { IncomeFromAnySource: 0 } if Random.new(@rng_seed).rand < no_income_prob

        sources = (@income_cfg['sources'] || {}).transform_values(&:to_f)
        return { IncomeFromAnySource: 0 } if sources.values.sum.zero?

        cfg = { 'distribution' => 'weighted', 'weights' => sources }
        selected = Distribution.sample(cfg, rng: Random.new(@rng_seed + 1))
        source = INCOME_SOURCES[selected]
        unless source
          Rails.logger.warn { "HmisSimulation::IncomeBenefitBuilder: unknown income source key #{selected.inspect}; defaulting to no income" }
          return { IncomeFromAnySource: 0 }
        end

        amount = Random.new(@rng_seed + 2).rand(source[:typical_amount] * 0.5..source[:typical_amount] * 1.5).round
        {
          IncomeFromAnySource: 1,
          source[:field] => 1,
          source[:amount_field] => amount,
          TotalMonthlyIncome: amount,
        }
      end
    end
  end
end
