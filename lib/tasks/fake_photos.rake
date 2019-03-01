namespace :fake_photos do

  desc "Fetch new fake photos from https://thispersondoesnotexist.com/image"
  task :fetch, [:count] => [:environment, "log:info_to_stdout"] do |task, args|
    require 'open-uri'
    count = args.try(:[], :count)&.to_i
    count = 1 if count < 1 
    url = 'https://thispersondoesnotexist.com/image'
    path = File.join('public', 'fake_photos')
    count.times do |i|
      sleep(1)
      file_name = "client_photo_#{i}.jpg"
      open("#{url}?#{i}") do |u|
        File.open(File.join(path, file_name), 'wb') { |f| f.write(u.read) }
      end
    end
  end

end
