###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Shape::Installer, type: :model do
  let!(:config) { GrdaWarehouse::Config.where(id: 1).first_or_create }
  let(:installer) { described_class.new }

  before do
    GrdaWarehouse::Config.where.not(id: 1).delete_all
    GrdaWarehouse::Config.invalidate_cache
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  describe '#make_inserts_command' do
    it 'passes the state codes as a separate argument' do
      config.update!(relevant_state_codes: 'VT,MA')

      expect(installer.make_inserts_command('states')).to eq(['./shape_files/states/make.inserts', 'VT,MA'])
    end

    it 'drops a stored code that is not two uppercase letters' do
      config.update_column(:relevant_state_codes, 'VT,MA;NH')

      expect(installer.make_inserts_command('states')).to eq(['./shape_files/states/make.inserts', 'VT'])
    end
  end

  describe '#handle_one_geography!' do
    it 'runs make.inserts with the codes as their own argument' do
      config.update!(relevant_state_codes: 'VT')
      conf = OpenStruct.new(klass: GrdaWarehouse::Shape::State, dir: 'states')
      # Skip the S3 download and the insert step.
      allow(installer).to receive(:sync_files_if_needed!)
      allow(installer).to receive(:system).and_return(true)
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with('shape_files/states/inserts.sql').and_return(false)

      installer.handle_one_geography!(conf)

      expect(installer).to have_received(:system).with('./shape_files/states/make.inserts', 'VT')
    end
  end
end
