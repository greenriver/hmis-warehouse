# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::CareplansController, type: :controller do
  let!(:user) { create :acl_user }
  let!(:admin_role) { create :admin_role }
  let!(:patient) { create :patient }
  let!(:client) { patient.client }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, admin_role, Collection.system_collection(:data_sources))
    sign_in user
  end

  describe 'string mutation operations' do
    let(:controller_instance) { described_class.new }

    before do
      allow(controller_instance).to receive(:current_user).and_return(user)
      controller_instance.instance_variable_set(:@patient, patient)
      controller_instance.instance_variable_set(:@client, client)
    end

    describe '#pctp method PDF concatenation' do
      let(:mock_pdf) { [] }
      let(:careplan) { double('careplan', updated_at: Time.current) }

      before do
        allow(controller_instance).to receive(:careplan_pdf_coversheet).and_return(mock_pdf)
        allow(controller_instance).to receive(:careplan_pdf_pctp).and_return('PCTP content')
        allow(controller_instance).to receive(:send_data)
        controller_instance.instance_variable_set(:@careplan, careplan)
        controller_instance.instance_variable_set(:@document, 'pctp')
      end

      it 'concatenates PDF content using << operator when calling pctp method' do
        controller_instance.send(:pctp)

        # Verify that the << operation from line 108 worked: pdf << careplan_pdf_pctp
        expect(mock_pdf).to include('PCTP content')
        expect(mock_pdf.length).to eq(1)
      end
    end

    describe '#careplan_params method with conditional array building' do
      before do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(
            {
              health_careplan: {
                initial_date: Date.current,
                ncm_approval: '1',
                rn_approval: '1',
                health_file_attributes: { file: 'test.pdf' },
              },
            },
          ),
        )
      end

      context 'when user has both approval permissions' do
        it 'includes both approval fields in params array using << operations' do
          allow(user).to receive(:can_approve_cha?).and_return(true)
          allow(user).to receive(:can_approve_careplan?).and_return(true)

          result = controller_instance.send(:careplan_params)

          # Verify the << operations from lines 173-174 worked correctly
          expect(result.permitted?).to be_truthy
          expect(result[:ncm_approval]).to eq('1')
          expect(result[:rn_approval]).to eq('1')
        end
      end

      context 'when user has no approval permissions' do
        it 'excludes approval fields from params array' do
          allow(user).to receive(:can_approve_cha?).and_return(false)
          allow(user).to receive(:can_approve_careplan?).and_return(false)

          result = controller_instance.send(:careplan_params)

          # Approval fields should not be included when permissions are false
          expect(result.permitted?).to be_truthy
          expect(result[:ncm_approval]).to be_nil
          expect(result[:rn_approval]).to be_nil
        end
      end

      context 'when user has partial approval permissions' do
        it 'includes only ncm_approval when user can approve CHA but not careplan' do
          allow(user).to receive(:can_approve_cha?).and_return(true)
          allow(user).to receive(:can_approve_careplan?).and_return(false)

          result = controller_instance.send(:careplan_params)

          # Only ncm_approval should be included
          expect(result.permitted?).to be_truthy
          expect(result[:ncm_approval]).to eq('1')
          expect(result[:rn_approval]).to be_nil
        end

        it 'includes only rn_approval when user can approve careplan but not CHA' do
          allow(user).to receive(:can_approve_cha?).and_return(false)
          allow(user).to receive(:can_approve_careplan?).and_return(true)

          result = controller_instance.send(:careplan_params)

          # Only rn_approval should be included
          expect(result.permitted?).to be_truthy
          expect(result[:ncm_approval]).to be_nil
          expect(result[:rn_approval]).to eq('1')
        end
      end

      context 'when testing core parameter structure' do
        it 'always includes base parameters regardless of permissions' do
          allow(user).to receive(:can_approve_cha?).and_return(false)
          allow(user).to receive(:can_approve_careplan?).and_return(false)

          result = controller_instance.send(:careplan_params)

          # Base parameters should always be included
          expect(result.permitted?).to be_truthy
          expect(result[:initial_date]).to eq(Date.current)
        end
      end
    end
  end
end
