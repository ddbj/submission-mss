module ExtractionFile
  def fullpath = extraction.working_dir.join(name)
  def size     = fullpath.size
end
