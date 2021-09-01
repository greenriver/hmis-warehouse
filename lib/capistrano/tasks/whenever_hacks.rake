# Because of limited access to sudo, we construct the cron file ourselves even
# though the whenever gem technicaly do it.
task :prime_whenever do
  on roles([:cron, :production_cron, :staging_cron]) do
    cmds = []

    cmds << "cd #{fetch(:release_path)}"

    old_cron = capture("sudo crontab -u #{fetch(:cron_user)} -l")
    # NOTE: this will need to be adjusted for each ruby version
    new_section = capture("bash -l -c 'cd #{fetch(:release_path)} && /usr/local/rvm/bin/rvm 2.7.4@global do bundle exec whenever --set \"environment=#{fetch(:rails_env)}\"'")

    new_section.sub!(/^.+your crontab file was not.+$/, '')
    new_section.sub!(/^.+whenever --help.+$/, '')

    start_line = "# Begin Whenever generated tasks for: #{fetch(:whenever_identifier)}\n"
    end_line = "# End Whenever generated tasks for: #{fetch(:whenever_identifier)}\n"

    File.open('.new_cron', 'w') do |new_cron|
      copy = true
      old_cron.each_line do |line|
        copy = false if line == start_line
        new_cron.write(line) if copy
        copy = true if line == end_line
      end

      new_cron.write(start_line)
      new_cron.write(new_section)
      new_cron.write(end_line)
    end

    upload!('.new_cron', "#{fetch(:release_path)}/.new_cron")
    File.unlink('.new_cron')
  end
end
