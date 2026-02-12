# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../config/deploy/docker/lib/deployer'

RSpec.describe Deployer do
  let(:args) do
    {
      service_registry_arns: ['arn:aws:servicediscovery:us-east-1:123456789012:service/srv-1234567890123456'],
      target_group_name: 'test-tg',
      secrets_arn: 'arn:aws:secretsmanager:us-east-1:123456789012:secret:test-secret',
      execution_role: 'arn:aws:iam::123456789012:role/ecsTaskExecutionRole',
      task_role: 'arn:aws:iam::123456789012:role/ecsTaskRole',
      fqdn: 'test.example.com',
      web_options: { cpu: 256, memory: 512 },
      registry_id: '123456789012',
      repo_name: 'test-repo',
    }
  end

  let(:revision) { 'a' * 40 }
  let(:version) { revision[0..6] }

  before do
    # Global mock for backticks to prevent actual git commands
    allow_any_instance_of(Object).to receive(:`).and_return('')
    allow_any_instance_of(Object).to receive(:`).with('git rev-parse HEAD').and_return(revision)

    allow(Dir).to receive(:chdir)
    allow(File).to receive(:realpath).and_return('/app')
    allow(File).to receive(:write)

    # Mock AWS client methods
    allow(AwsSdkHelpers::ClientMethods).to receive(:ecr).and_return(instance_double(Aws::ECR::Client))
    allow(AwsSdkHelpers::ClientMethods).to receive(:secretsmanager).and_return(instance_double(Aws::SecretsManager::Client))
    allow(AwsSdkHelpers::ClientMethods).to receive(:elbv2).and_return(instance_double(Aws::ElasticLoadBalancingV2::Client))
  end

  describe '#initialize' do
    it 'sets up the correct attributes' do
      deployer = Deployer.new(args)
      expect(deployer.revision).to eq(revision)
      expect(deployer.version).to eq(version)
      expect(deployer.cluster).to eq('openpath')
    end

    it 'uses provided revision if present' do
      custom_revision = 'b' * 40
      deployer = Deployer.new(args.merge(revision: custom_revision))
      expect(deployer.revision).to eq(custom_revision)
      expect(deployer.version).to eq(custom_revision[0..6])
    end
  end

  describe '#_initial_steps' do
    let(:deployer) { Deployer.new(args) }
    let(:ecr_client) { AwsSdkHelpers::ClientMethods.ecr }
    let(:secrets_client) { AwsSdkHelpers::ClientMethods.secretsmanager }

    before do
      # Mock docker login
      auth_token = Base64.encode64('user:pass')
      allow(ecr_client).to receive(:get_authorization_token).and_return(
        double(to_h: { authorization_data: [{ authorization_token: auth_token, proxy_endpoint: 'https://repo.url' }] }),
      )
      allow(deployer).to receive(:_run)

      # Mock image check
      allow(deployer).to receive(:_revision_not_in_repo?).and_return(false)

      # Mock secrets check
      allow(secrets_client).to receive(:describe_secret)

      # Mock git check
      allow(Deployer).to receive(:check_that_you_pushed_to_remote!)
    end

    it 'runs through initial steps successfully' do
      deployer.send(:_initial_steps)

      expect(deployer).to have_received(:_run).with(/docker login/, any_args)
      expect(secrets_client).to have_received(:describe_secret).with(secret_id: args[:secrets_arn])
      expect(File).to have_received(:write).with(any_args, revision)
    end
  end

  describe '#run!' do
    let(:deployer) { Deployer.new(args) }
    let(:roll_out) { instance_double(RollOut) }

    before do
      allow(deployer).to receive(:_initial_steps)
      allow(deployer).to receive(:roll_out).and_return(roll_out)
      allow(roll_out).to receive(:run!)
      allow(deployer).to receive(:_add_latest_tag!)
    end

    it 'calls initial steps, roll_out.run! and adds latest tag' do
      deployer.run!

      expect(deployer).to have_received(:_initial_steps)
      expect(roll_out).to have_received(:run!)
      expect(deployer).to have_received(:_add_latest_tag!)
    end
  end

  describe '#_add_latest_tag!' do
    let(:deployer) { Deployer.new(args) }
    let(:ecr_client) { AwsSdkHelpers::ClientMethods.ecr }
    let(:image_tag) { "githash-#{version}" }
    let(:latest_tag) { "latest-#{args[:target_group_name]}" }

    before do
      deployer.send(:_set_image_tag!)
    end

    it 'updates the latest tag when it is not even with current tag' do
      image = double(image_id: double(image_tag: image_tag), image_manifest: 'manifest-content')
      allow(ecr_client).to receive(:batch_get_image).and_return(double(images: [image]))
      allow(ecr_client).to receive(:put_image).and_return(double(to_h: { result: 'ok' }))

      expect { deployer.send(:_add_latest_tag!) }.to output(/is now even with/).to_stdout

      expect(ecr_client).to have_received(:put_image).with(hash_including(
                                                             image_tag: latest_tag,
                                                             image_manifest: 'manifest-content',
                                                           ))
    end

    it 'skips update if latest tag is already even' do
      image1 = double(image_id: double(image_tag: image_tag, image_digest: 'digest1'))
      image2 = double(image_id: double(image_tag: latest_tag, image_digest: 'digest1'))
      allow(ecr_client).to receive(:batch_get_image).and_return(double(images: [image1, image2]))

      expect { deployer.send(:_add_latest_tag!) }.to output(/is already even with/).to_stdout
      expect(ecr_client).not_to receive(:put_image)
    end

    it 'raises error if no images found' do
      allow(ecr_client).to receive(:batch_get_image).and_return(double(images: []))
      expect { deployer.send(:_add_latest_tag!) }.to raise_error(/No images matching tag/)
    end
  end

  describe '#_target_group_arn' do
    let(:deployer) { Deployer.new(args) }
    let(:elbv2_client) { AwsSdkHelpers::ClientMethods.elbv2 }

    context 'when USE_LEGACY_TARGET_GROUP_ARN_BEHAVIOR is true' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('USE_LEGACY_TARGET_GROUP_ARN_BEHAVIOR').and_return('true')
      end

      it 'returns ARN from describe_target_groups' do
        tg = double(target_group_name: args[:target_group_name], target_group_arn: 'arn:tg-123')
        allow(elbv2_client).to receive(:describe_target_groups).and_return(double(target_groups: [tg]))

        expect(deployer.send(:_target_group_arn)).to eq('arn:tg-123')
      end
    end

    context 'when USE_LEGACY_TARGET_GROUP_ARN_BEHAVIOR is not true' do
      let(:blue_green) { instance_double(BlueGreen) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('USE_LEGACY_TARGET_GROUP_ARN_BEHAVIOR').and_return('false')
        allow(BlueGreen).to receive(:new).and_return(blue_green)
      end

      it 'returns ARN from BlueGreen' do
        allow(blue_green).to receive(:check!)
        allow(blue_green).to receive(:target_group_to_deploy_to).and_return(double(target_group_arn: 'arn:tg-bg'))

        expect(deployer.send(:_target_group_arn)).to eq('arn:tg-bg')
      end
    end
  end

  describe '.check_that_you_pushed_to_remote!' do
    let(:branch) { 'main' }
    let(:our_commit) { 'abcdef123456' }

    before do
      allow_any_instance_of(Object).to receive(:`).with('git rev-parse --abbrev-ref HEAD').and_return(branch)
      allow_any_instance_of(Object).to receive(:`).with(/git ls-remote origin/).and_return(our_commit)
      allow_any_instance_of(Object).to receive(:`).with("git rev-parse #{branch}").and_return(our_commit)
    end

    it 'does not raise error if remote is up to date' do
      expect { Deployer.check_that_you_pushed_to_remote! }.not_to raise_error
    end

    it 'raises error if remote is not up to date' do
      allow_any_instance_of(Object).to receive(:`).with(/git ls-remote origin/).and_return('different_commit')
      expect { Deployer.check_that_you_pushed_to_remote! }.to raise_error(/Push or pull your branch first!/)
    end
  end
end
