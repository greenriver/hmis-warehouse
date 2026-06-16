# frozen_string_literal: true

namespace :code do
  # NOTE, you can check a PR for this with
  # git diff -U0 --minimal HEAD~1 | grep -v '^+#.*2024' | grep -v '^+#.*LICENSE.md' | grep -v '^+###$' | grep -v '^+#$' | grep -v '^diff --git' | grep -v '^index' | grep '^--- a' | grep '^+++ b' | more
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

  # Intentionally excludes spec/, config/, bin/ — those must be updated manually
  # or via a targeted one-liner when the copyright format changes.
  def files
    Dir.glob("#{Rails.root}/app/{**/}*.rb") +
      Dir.glob("#{Rails.root}/drivers/{**/}*.rb") +
      Dir.glob("#{Rails.root}/lib/{**/}*.rb")
  end

  def add_copyright_to_file(path)
    content = File.read(path)

    return if content.start_with?(::Code.copyright_header)

    puts ">>> Updating copyright in #{path}"
    @modified += 1

    # Strip old-format header before prepending — otherwise files that already
    # have a copyright block end up with two headers stacked at the top.
    content = ::Code.strip_old_copyright(content)

    tempfile = Tempfile.new('with_copyright')
    tempfile.write(::Code.copyright_header)
    tempfile.write(content)
    tempfile.flush
    tempfile.close
    FileUtils.cp(tempfile.path, path)
  end
end
