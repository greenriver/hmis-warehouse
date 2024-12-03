require 'rails_helper'

RSpec.describe HasPiiAttributes do
  # Example model classes for testing
  let(:test_pii_model) do
    Class.new do
      include HasPiiAttributes

      def self.columns
        []
      end

      attr_accessor :first_name, :last_name, :ssn, :dob, :notes
    end
  end

  class InvalidPiiModel
    include HasPiiAttributes
  end

  describe 'class methods' do
    describe '.pii_attr' do
      context 'with valid attributes' do
        let(:model) do
          Class.new(test_pii_model) do
            pii_attr :first_name
            pii_attr :last_name, required: true
            pii_attr :ssn, level: 1
            pii_attr :dob, as: :dob, level: 2
            pii_attr :notes, as: :free_text, level: 4
          end
        end

        it 'registers PII attributes' do
          expect(model.pii_attributes_config.keys).to match_array(
            [:first_name, :last_name, :ssn, :dob, :notes],
          )
        end

        it 'sets default sensitivity levels based on type' do
          expect(model.pii_attributes_config[:first_name][:level]).to eq(1)
        end

        it 'allows overriding sensitivity levels' do
          expect(model.pii_attributes_config[:notes][:level]).to eq(4)
        end

        it 'sets required flag' do
          expect(model.pii_attributes_config[:last_name][:required]).to be true
          expect(model.pii_attributes_config[:first_name][:required]).to be false
        end

        it 'maps attributes to correct PII types' do
          expect(model.pii_attributes_config[:notes][:type]).to eq(:free_text)
          expect(model.pii_attributes_config[:first_name][:type]).to eq(:first_name)
        end
      end

      context 'with invalid attributes' do
        it 'raises error for unknown PII type' do
          expect do
            Class.new(test_pii_model) do
              pii_attr :something, as: :invalid_type
            end
          end.to raise_error(ArgumentError, /unknown pii data type/)
        end

        it 'raises error for invalid sensitivity level' do
          expect do
            Class.new(test_pii_model) do
              pii_attr :first_name, level: 0
            end
          end.to raise_error(ArgumentError, /unknown pii sensitivity level/)

          expect do
            Class.new(test_pii_model) do
              pii_attr :first_name, level: 5
            end
          end.to raise_error(ArgumentError, /unknown pii sensitivity level/)
        end
      end

      context 'when redefining attributes' do
        let(:model) do
          Class.new(test_pii_model) do
            pii_attr :first_name, level: 1
            pii_attr :first_name, level: 2 # Redefine with different level
          end
        end

        it 'uses the latest definition' do
          expect(model.pii_attributes_config[:first_name][:level]).to eq(2)
        end
      end
    end

    describe '.stores_pii?' do
      it 'returns true when PII attributes are configured' do
        model = Class.new(test_pii_model) do
          pii_attr :first_name
        end
        expect(model.stores_pii?).to be true
      end

      it 'returns false when no PII attributes are configured' do
        model = Class.new(test_pii_model)
        expect(model.stores_pii?).to be false
      end
    end
  end

  describe 'inheritance' do
    let(:parent_class) do
      Class.new(test_pii_model) do
        pii_attr :first_name
        pii_attr :last_name
      end
    end

    let(:child_class) do
      Class.new(parent_class) do
        pii_attr :ssn
        pii_attr :last_name, level: 2 # Override parent's last_name
      end
    end

    it 'inherits PII attributes from parent' do
      expect(child_class.pii_attributes_config.keys).to include(:first_name)
    end

    it 'allows adding new PII attributes' do
      expect(child_class.pii_attributes_config.keys).to include(:ssn)
    end

    it 'allows overriding parent PII attributes' do
      expect(child_class.pii_attributes_config[:last_name][:level]).to eq(2)
      expect(parent_class.pii_attributes_config[:last_name][:level]).to eq(1)
    end
  end
end
