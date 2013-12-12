class File
  def self.in_path(filename, search_path = Spread2RDF::SEARCH_PATH)
    return filename if File.exist? filename
    search_path.each do |path|
      file = File.join(path, filename)
      return file if File.exist? file
    end
    nil
  end
end