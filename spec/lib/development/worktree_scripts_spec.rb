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
      before { write('.envrc', "export FQDN=hmis-warehouse.dev.test\nexport TRAEFIK_ENABLED=true\nexport TRAEFIK_ROUTER_NAME=op\n") }

      it 'names the compose project and web container after the branch' do
        run_update
        expect(read('.envrc')).to include("export COMPOSE_PROJECT_NAME=hmis-warehouse-feature-x\n")
        expect(override.dig('services', 'web', 'container_name')).to eq('hmis-warehouse-web-feature-x')
        expect(override.dig('volumes', 'bundle_trixie', 'name')).to eq('hmis-warehouse_bundle_trixie')
      end

      it 'turns traefik off when the primary .envrc enables it' do
        run_update
        expect(read('.envrc').scan(/^export TRAEFIK_ENABLED=.*$/)).to eq(['export TRAEFIK_ENABLED=false'])
      end
    end

    context 'when the primary .envrc exports NAME_PREFIX more than once' do
      before { write('.envrc', "export NAME_PREFIX=old-\nexport NAME_PREFIX=ai-\n") }

      it 'uses the last value, as direnv does' do
        run_update
        expect(read('.envrc')).to include("export COMPOSE_PROJECT_NAME=ai-hmis-warehouse-feature-x\n")
      end
    end

    context 'when NAME_PREFIX is not lowercase letters, digits, and hyphens' do
      before { write('.envrc', "export NAME_PREFIX=AI-\n") }

      it 'exits with an error before rewriting any file' do
        _out, err, status = Open3.capture3('ruby', scripts.join('update_worktree_env.rb').to_s, dir, 'feature/X')
        expect(status.success?).to be(false)
        expect(err).to include('NAME_PREFIX')
        expect(read('.envrc')).to eq("export NAME_PREFIX=AI-\n")
        expect(File.exist?(File.join(dir, '.env.test.local'))).to be(false)
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

    context 'when the primary .env.test.local sets only some test database names' do
      before do
        write('.envrc', "export NAME_PREFIX=ai-\n")
        write('.env.test', "DATABASE_APP_DB_TEST=app_test\nWAREHOUSE_DATABASE_DB_TEST=warehouse_test\n")
        write('.env.test.local', "WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test\n")
      end

      it 'suffixes the keys .env.test.local lacks from .env.test so none fall through to the primary' do
        run_update
        expect(read('.env.test.local').lines(chomp: true)).to contain_exactly(
          'WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test_wt_feature_x',
          'DATABASE_APP_DB_TEST=app_test_wt_feature_x',
        )
      end
    end

    context 'when the primary .envrc names a compose project that does not match NAME_PREFIX' do
      before { write('.envrc', "export NAME_PREFIX=ai-\nexport COMPOSE_PROJECT_NAME=ai-warehouse\n") }

      it 'exits with an error naming both values' do
        _out, err, status = Open3.capture3('ruby', scripts.join('update_worktree_env.rb').to_s, dir, 'feature/X')
        expect(status.success?).to be(false)
        expect(err).to include('COMPOSE_PROJECT_NAME').and include('ai-hmis-warehouse')
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

    context 'when a comment indented like a service key sits inside the override web block' do
      before do
        write('.envrc', "export NAME_PREFIX=ai-\n")
        write('docker-compose.override.yml', <<~YAML)
          services:
            web:
            # apple silicon
              platform: linux/arm64
              container_name: ai-hmis-warehouse-web
        YAML
      end

      it 'replaces the container_name after the comment instead of adding a second one' do
        run_update
        expect(read('docker-compose.override.yml').scan(/container_name: .*web.*/)).to eq(['container_name: ai-hmis-warehouse-web-feature-x'])
        expect(override.dig('services', 'web', 'platform')).to eq('linux/arm64')
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

    def run_pre_start
      _out, err, status = Open3.capture3('bash', scripts.join('worktree_pre_start.sh').to_s, dir, 'feature/X', primary)
      raise err unless status.success?
    end

    it 'suffixes the test database names the primary .env.test.local sets' do
      File.write(File.join(primary, '.env.test.local'), "WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test\n")
      write('.env.test', "WAREHOUSE_DATABASE_DB_TEST=warehouse_test\n")
      run_pre_start

      expect(read('.env.test.local')).to eq("WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test_wt_feature_x\n")
    end

    it 'copies the primary CLAUDE.local.md into the worktree' do
      File.write(File.join(primary, 'CLAUDE.local.md'), "primary notes\n")
      run_pre_start

      expect(read('CLAUDE.local.md')).to eq("primary notes\n")
    end

    it 'keeps a CLAUDE.local.md the worktree already has' do
      File.write(File.join(primary, 'CLAUDE.local.md'), "primary notes\n")
      write('CLAUDE.local.md', "worktree notes\n")
      run_pre_start

      expect(read('CLAUDE.local.md')).to eq("worktree notes\n")
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
      write('.envrc', "export NAME_PREFIX=ai-\t\nexport COMPOSE_PROJECT_NAME=ai-hmis-warehouse-feature-x\n")
      write('.env.local', <<~ENV)
        DATABASE_APP_DB=development_openpath_app
        WAREHOUSE_DATABASE_DB=development_openpath_warehouse_wt_feature_x
      ENV
      write('.env.test.local', "WAREHOUSE_DATABASE_DB_TEST=ai_warehouse_test_wt_feature_x\n")
    end

    def run_remove
      env = { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}" }
      _out, err, status = Open3.capture3(env, 'bash', scripts.join('worktree_pre_remove.sh').to_s, dir, 'feature/X')
      raise err unless status.success?

      File.readlines(log, chomp: true)
    end

    it 'drops the dev and test _wt_ databases in the db container named by the worktree .envrc, ignoring trailing whitespace' do
      calls = run_remove
      expect(calls).to include('compose -p ai-hmis-warehouse-feature-x down --remove-orphans')
      expect(calls.grep(/^exec /)).to contain_exactly(
        'exec ai-hmis-warehouse-db psql -U postgres -tc DROP DATABASE IF EXISTS "development_openpath_warehouse_wt_feature_x" WITH (FORCE);',
        'exec ai-hmis-warehouse-db psql -U postgres -tc DROP DATABASE IF EXISTS "ai_warehouse_test_wt_feature_x" WITH (FORCE);',
      )
    end

    it 'never runs compose down against the primary project named in a stale .envrc, even when the branch name is its suffix' do
      write('.envrc', "export NAME_PREFIX=ai-\nexport COMPOSE_PROJECT_NAME=ai-hmis-warehouse\n")
      env = { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}" }
      _out, _err, status = Open3.capture3(env, 'bash', scripts.join('worktree_pre_remove.sh').to_s, dir, 'hmis-warehouse')
      expect(status.success?).to be(true)
      expect(File.readlines(log, chomp: true).grep(/^compose /)).to eq(['compose -p ai-hmis-warehouse-hmis-warehouse down --remove-orphans'])
    end
  end
end
