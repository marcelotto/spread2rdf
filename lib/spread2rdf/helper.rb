module Spread2RDF
  module Helper

  module_function

    # TODO: include this in the MappingContext(s)
    def resource_name(string)
      string
        .gsub(', ', '-')
        .gsub(' ', '-')
    end

  end
end
