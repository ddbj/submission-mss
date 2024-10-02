module TmpUploadedFile
  refine Rack::Test::UploadedFile.singleton_class do
    def tmp(filename, content: "")
      Dir.mktmpdir { |dir|
        file = Pathname.new(dir).join(filename).open("wb").tap { |f|
          f.write content
          f.rewind
        }

        new(file)
      }
    end
  end
end
