# frozen_string_literal: true

namespace :code do
  # NOTE, before you commit, you can check a PR for this with
  # git diff -U0 --minimal HEAD~1 | grep -v '^+#.*2024' | grep -v '^+#.*LICENSE.md' | grep -v '^+###$' | grep -v '^+#$' | grep -v '^diff --git' | grep -v '^index' | grep '^--- a' | grep '^+++ b' | more
  #
  # To review a branch vs main, skipping files where the only changes
  # are the copyright notice and/or frozen_string_literal, write to a diff file:
  #   branch=dg-copyright-update; \
  #   git diff -w main...$branch --name-only | while read f; do \
  #     extra=$(git diff -U0 -w main...$branch -- "$f" | grep '^[+-]' | \
  #       grep -v '^---' | grep -v '^+++' | \
  #       grep -v '^[-+]$' | \
  #       grep -v '^[-+]###$' | \
  #       grep -v '^[-+]#$' | \
  #       grep -v '^[-+]# License detail:' | \
  #       grep -vE '^-# Copyright [0-9]{4} - [0-9]{4} Green River Data Analysis, LLC' | \
  #       grep -v '^+# Copyright Green River Data Group, Inc.' | \
  #       grep -v '^[-+]# frozen_string_literal: true'); \
  #     [ -n "$extra" ] && git diff -w main...$branch -- "$f"; \
  #   done > tmp/changes.diff
  desc 'Ensure the copyright is included in all ruby files'
  task :maintain_copyright, [] => [:environment, 'log:info_to_stdout'] do
    puts 'Adding license text in all .rb files that don\'t already have it'
    puts ::Code.copyright_header
    @modified = 0
    files.each do |path|
      add_copyright_to_file(path)
    end

    puts "Modified #{@modified} #{'record'.pluralize(@modified)}"
  end

  # rails code:generate_hud_lists
  # rails code:generate_hud_list_json\["2024","lib/data/CSV Specifications Machine-Readable_FY2024.xlsx"\]
  desc 'Generate HUD list json file'
  task :generate_hud_list_json, [:year, :csv_file_path] => [:environment, 'log:info_to_stdout'] do |_task, args|
    HudCodeGen.generate_hud_list_json(args.year.to_i, args.csv_file_path)
  end

  desc 'Generate HUD list mapping module'
  task :generate_hud_lists, [:year] => [:environment, 'log:info_to_stdout'] do |_task, args|
    filenames = []
    ['2022', '2024', '2026'].
      filter { |year| args.year.nil? || args.year == year }.
      each { |year| filenames << HudCodeGen.generate_hud_lists(year) }
    exec("bundle exec rubocop -A --format simple #{filenames.join(' ')} > /dev/null")
  end

  def files
    Dir.glob("#{Rails.root}/app/{**/}*.rb") +
      Dir.glob("#{Rails.root}/drivers/{**/}*.rb") +
      Dir.glob("#{Rails.root}/lib/{**/}*.rb") +
      Dir.glob("#{Rails.root}/spec/{**/}*.rb") +
      Dir.glob("#{Rails.root}/config/{**/}*.rb") +
      Dir.glob("#{Rails.root}/bin/*.rb")
  end

  def add_copyright_to_file(path)
    content = File.read(path)

    # Shebang lines must stay on line 1 — extract before any other processing.
    shebang = content.slice!(/\A#![^\n]*\n/)

    return if content.start_with?(::Code.copyright_header)

    puts ">>> Updating copyright in #{path}"
    @modified += 1

    # Strip old-format header before prepending — otherwise files that already
    # have a copyright block end up with two headers stacked at the top.
    content = ::Code.strip_old_copyright(content)

    tempfile = Tempfile.new('with_copyright')
    tempfile.write(shebang) if shebang
    tempfile.write(::Code.copyright_header)
    tempfile.write(content)
    tempfile.flush
    tempfile.close
    FileUtils.cp(tempfile.path, path)
  end
end
