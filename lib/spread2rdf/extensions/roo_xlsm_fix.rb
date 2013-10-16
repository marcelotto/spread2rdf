require 'zip'
#require 'zip/zipfilesystem'
# source (adapted to newer version of Roo and ruby-zip): https://gist.github.com/roblingle/1333908

# Easy access to xlsm files through the roo gem, version 1.10.0.
# The error that led me to write this is in the file below for google fodder. Not exactly sure what was causing
# the problem, so I'm not sure that this change won't break everything on your computer or summon zombies.
#
# Be sure to tell roo that you don't care about the extension mismatch:
# xl = Roo::Excelx.new("C:/path/to/spreadsheet_with_macro.xlsm", :zip, :warning)
#
class Roo::Excelx

  alias :old_initialize :initialize
  def initialize(filename, options = {}) # , packed=nil, file_warning = :error)
    @original_file = filename
    old_initialize(filename, options)
  end

  # extract files from the zip file, rewrites a method of the same name in lib/roo/excelx.rb
  def extract_content(tmpdir, zipfilename_unused)
    #Zip::ZipFile.open(@original_file) do |zip|
    Zip::File.open(@original_file) do |zip|
      process_zipfile(tmpdir, @original_file, zip)
    end
  end

end
