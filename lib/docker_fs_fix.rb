# https://github.com/docker/for-linux/issues/1015

puts "Patching https://github.com/docker/for-linux/issues/1015"
module FileUtilsPatch
  def copy_file(dest)
    FileUtils.touch(path())
    super
  end
end

module FileUtils
  class Entry_
    prepend FileUtilsPatch
  end
end
