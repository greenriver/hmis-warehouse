###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'open3'

RSpec.describe 'worktree hook scripts' do
  let(:scripts) { Rails.root.join('lib/development/scripts') }
  let(:dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(dir) }

  def write(name, body) = File.write(File.join(dir, name), body)
  def read(name) = File.read(File.join(dir, name))

  describe 'update_worktree_env.rb' do
    let(:managed_files) { ['.envrc', '.env.local', '.env.test.local', 'docker-compose.override.yml'] }

    def run_update(branch = 'feature/X')
      _out, err, status = Open3.capture3('ruby', scripts.join('update_worktree_env.rb').to_s, dir, branch)
      raise err unless status.success?
    end

    def override = YAML.safe_load(read('docker-compose.override.yml'))

    before do
      write('.env.test', "WAREHOUSE_DATABASE_DB_TEST=warehouse_test\n")
      write('.env.local', "WAREHOUSE_DATABASE_DB=development_openpath_warehouse\n")
      write('docker-compose.override.yml', <<~YAML)
        services:
          web:
            platform: linux/arm64
        volumes:
          bundle_trixie:
      YAML
    end

    context 'when the primary .envrc has no NAME_PREFIX' do
      before { write('.envrc', "export TRAEFIK_ENABLED=true\n") }

      it 'names the compose project and web container after the branch' do
        run_update
        expect(read('.envrc')).to include("export COMPOSE_PROJECT_NAME=hmis-warehouse-feature-x\n")
        expect(override.dig('services', 'web', 'container_name')).to eq('hmis-warehouse-web-feature-x')
        expect(override.dig('volumes', 'bundle_trixie', 'name')).to eq('hmis-warehouse_bundle_trixie')
      end

      it 'turns traefik off so the worktree web cannot claim the primary domain' do
        run_update
        expect(read('.envrc').scan(/^export TRAEFIK_(?:ENABLED|ROUTER_NAME)=.*$/)).to eq(['export TRAEFIK_ENABLED=false'])
      end
    end

    context 'when the primary .envrc sets NAME_PREFIX=ai-' do
      before { write('.envrc', "export NAME_PREFIX=ai-\nexport TRAEFIK_ENABLED=true\n") }

      it 'prefixes the compose project, container, and shared volume names' do
        run_update
        expect(read('.envrc')).to include("export COMPOSE_PROJECT_NAME=ai-hmis-warehouse-feature-x\n")
        expect(override.dig('services', 'web', 'container_name')).to eq('ai-hmis-warehouse-web-feature-x')
        expect(override.dig('services', 'yarn', 'container_name')).to eq('ai-hmis-warehouse-yarn-feature-x')
        expect(override.dig('volumes', 'bundle_trixie', 'name')).to eq('ai-hmis-warehouse_bundle_trixie')
      end

      it 'leaves every file byte-identical when run a second time' do
        run_update
        first_run = managed_files.map { |f| read(f) }
        run_update
        expect(managed_files.map { |f| read(f) }).to eq(first_run)
      end
    end

    context 'when the override web block already names a container' do
      before do
        write('.envrc', "export NAME_PREFIX=ai-\n")
        write('docker-compose.override.yml', <<~YAML)
          services:
            web:
              container_name: ai-hmis-warehouse-web
              labels:
                - traefik.docker.network=ai-sandbox
        YAML
      end

      it 'replaces that name rather than adding a duplicate key' do
        run_update
        web_names = read('docker-compose.override.yml').scan(/container_name: .*web.*/)
        expect(web_names).to eq(['container_name: ai-hmis-warehouse-web-feature-x'])
        expect(override.dig('services', 'web', 'labels')).to eq(['traefik.docker.network=ai-sandbox'])
      end
    end

    context 'when the primary override already loads .env.test.local into spec' do
      before do
        write('.envrc', "export NAME_PREFIX=ai-\n")
        write('docker-compose.override.yml', <<~YAML)
          services:
            spec:
              env_file:
                - .env.test.local
            web:
              labels:
                - traefik.docker.network=ai-sandbox
        YAML
      end

      it 'still names the yarn container and keeps a single spec env_file entry' do
        run_update
        expect(override.dig('services', 'yarn', 'container_name')).to eq('ai-hmis-warehouse-yarn-feature-x')
        expect(override.dig('services', 'spec', 'env_file')).to eq(['.env.test.local'])
      end
    end
  end

  describe 'worktree_pre_start.sh' do
    let(:primary) { Dir.mktmpdir }

    after { FileUtils.remove_entry(primary) }

    it 'suffixes the test database names the primary .env.test.local sets' do
      File.write(File.join(primary, '.env.test.local'), "WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test\n")
      write('.env.test', "WAREHOUSE_DATABASE_DB_TEST=warehouse_test\n")
      _out, err, status = Open3.capture3('bash', scripts.join('worktree_pre_start.sh').to_s, dir, 'feature/X', primary)
      raise err unless status.success?

      expect(read('.env.test.local')).to eq("WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test_wt_feature_x\n")
    end
  end

  describe 'worktree_pre_remove.sh' do
    let(:bin) { Dir.mktmpdir }
    let(:log) { File.join(bin, 'docker.log') }

    after { FileUtils.remove_entry(bin) }

    before do
      File.write(File.join(bin, 'docker'), <<~SH)
        #!/bin/sh
        echo "$*" >> "#{log}"
        [ "$1" = ps ] && echo ai-hmis-warehouse-db
        exit 0
      SH
      File.chmod(0o755, File.join(bin, 'docker'))
      write('.envrc', "export NAME_PREFIX=ai-\nexport COMPOSE_PROJECT_NAME=ai-hmis-warehouse-feature-x\n")
      write('.env.local', <<~ENV)
        DATABASE_APP_DB=development_openpath_app
        WAREHOUSE_DATABASE_DB=development_openpath_warehouse_wt_feature_x
      ENV
    end

    def run_remove
      env = { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}" }
      _out, err, status = Open3.capture3(env, 'bash', scripts.join('worktree_pre_remove.sh').to_s, dir, 'feature/X')
      raise err unless status.success?

      File.readlines(log, chomp: true)
    end

    it 'targets the compose project and db container named by the worktree .envrc' do
      calls = run_remove
      expect(calls).to include('compose -p ai-hmis-warehouse-feature-x down --remove-orphans')
      expect(calls.grep(/^exec /)).to contain_exactly(
        'exec ai-hmis-warehouse-db psql -U postgres -tc DROP DATABASE IF EXISTS "development_openpath_warehouse_wt_feature_x" WITH (FORCE);',
      )
    end
  end
end
