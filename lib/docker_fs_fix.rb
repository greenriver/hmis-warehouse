module DockerFsFix
  module_function def upload(upload)
    # Rack::Test::UploadedFile uploads are on tmpfs and many consumers
    # of them also copy to tmpfs. There is a bug here
    # under docker (https://github.com/docker/for-linux/issues/1015)
    # that breaks our tests. In dev/prod tmpfs does not appear to have this problem

    # This workaround can go away when a fix for the above makes it to GitHub Actions

    if (io = upload.tempfile)
      io.chmod io.lstat.mode
    end
    upload
  end
end
