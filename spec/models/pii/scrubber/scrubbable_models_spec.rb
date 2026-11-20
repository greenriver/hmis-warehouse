###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pii::Scrubber::ScrubbableModels do
  describe '.to_scrub' do
    subject(:models) { described_class.to_scrub }

    it 'includes PII models declared outside the legacy warehouse namespaces' do
      expect(models).to include(
        HmisDataQualityTool::CurrentLivingSituation,
        HmisExternalApis::AcHmis::ReferralPosting,
        HmisExternalApis::ExternalForms::FormSubmission,
        HmisCsvTwentyTwentySix::Importer::Client,
        HmisCsvTwentyTwentySix::Importer::User,
        HmisCsvTwentyTwentySix::Loader::Client,
        HmisCsvTwentyTwentySix::Loader::User,
        GrdaWarehouse::ClientFile,
        Hmis::File,
      )
    end

    it 'scrubs the shared SPM enrollment table through one model' do
      spm = models.select { |m| m.table_name == 'hud_report_spm_enrollments' }
      expect(spm.size).to eq(1)
    end

    it 'leaves out staff login accounts' do
      expect(models).not_to include(User, Hmis::User)
    end

    it 'scrubs an STI table once, through its base class' do
      expect(models).to include(GrdaWarehouse::Contact::Base, HudPit::Fy2022::PitClient, GrdaWarehouse::Hud::Client)
      expect(models).not_to include(
        GrdaWarehouse::Contact::Organization,
        HudPit::Fy2024::PitClient,
        GrdaWarehouse::Hud::WithDeleted::Client,
      )
    end

    it 'keeps an STI subclass whose PII config differs from its base class' do
      subclass = Class.new(GrdaWarehouse::Contact::Base) do
        def self.name = 'PiiExtraConfigContact'
        pii_attr :email, level: 1
      end
      stub_const('PiiExtraConfigContact', subclass)

      expect(described_class.to_scrub).to include(subclass)
    end

    it 'keeps unrelated models on one table when their PII configs differ' do
      first = Class.new(GrdaWarehouseBase) do
        include HasPiiAttributes
        self.table_name = 'contacts'
        def self.name = 'PiiSharedTableFirst'
        pii_attr :first_name
      end
      second = Class.new(GrdaWarehouseBase) do
        include HasPiiAttributes
        self.table_name = 'contacts'
        def self.name = 'PiiSharedTableSecond'
        pii_attr :last_name
      end
      stub_const('PiiSharedTableFirst', first)
      stub_const('PiiSharedTableSecond', second)

      expect(described_class.to_scrub).to include(first, second)
    end

    it 'covers every model left out of the scrub list with a scrubbed model on the same table and config' do
      left_out = described_class.all - models
      uncovered = left_out.reject do |model|
        models.any? do |kept|
          kept.connection_db_config.database == model.connection_db_config.database &&
            kept.table_name == model.table_name &&
            kept.pii_attributes_config == model.pii_attributes_config &&
            (kept == model.base_class || (kept.base_class == kept && model.base_class == model))
        end
      end

      expect(left_out).not_to be_empty
      expect(uncovered.map(&:name)).to eq([])
    end

    it 'scrubs the warehouse Client table through one model' do
      client = models.select { |m| m.table_name == 'Client' && m.connection_db_config == GrdaWarehouseBase.connection_db_config }
      expect(client.size).to eq(1)
    end

    it 'returns concrete PII models sorted by name' do
      expect(models).to all(satisfy { |m| m.stores_pii? && !m.abstract_class? })
      expect(models.map(&:name)).to eq(models.map(&:name).sort)
    end
  end

  describe '.all' do
    it 'keeps aliases and STI subclasses so their versions can be pruned' do
      expect(described_class.all).to include(Hmis::Hud::User, GrdaWarehouse::Contact::Organization, HudSpmReport::Fy2026::SpmEnrollment)
    end

    it 'leaves out staff login accounts' do
      expect(described_class.all).not_to include(User, Hmis::User)
    end

    it 'skips a model whose table does not exist' do
      no_table = Class.new(GrdaWarehouseBase) do
        include HasPiiAttributes
        self.table_name = 'no_such_pii_table'
        pii_attr :first_name
      end
      stub_const('PiiNoTable', no_table)

      expect(described_class.all).not_to include(no_table)
    end

    it 'skips a model whose constant is not registered under its name' do
      klass = Class.new(GrdaWarehouse::Contact::Base) do
        def self.name = 'PiiUnregisteredContact'
        pii_attr :email, level: 1
      end

      expect(described_class.all).not_to include(klass)
    end
  end
end
