module Spread2RDF
  module Attributes
    extend ActiveSupport::Concern

    module ClassMethods
      def attributes
        if superclass.respond_to?(:attributes) and
            (super_attributes = superclass.attributes).is_a? Hash
          @attributes ||= {}
          @attributes.reverse_merge(super_attributes)
        else
          @attributes
        end
      end

      def attributes=(defaults)
        defaults.each { |attribute, default_value| attr_accessor attribute }
        @attributes = @attributes.try(:merge, defaults) || defaults
      end
    end

    def init_attributes(initial_values)
      self.class.attributes.each do |attribute, default_value|
        instance_variable_set("@#{attribute}".to_sym,
          initial_values.delete(attribute) || default_value)
      end
      initial_values
    end

    def update_attributes(update_values)
      update_values.each do |attribute, value|
        next unless self.class.attributes.include? attribute
        instance_variable_set("@#{attribute}".to_sym, value)
      end
      update_values
    end

    def inspect
      "#{self}: " +
        self.class.attributes.map do |attribute, default_value|
          "#{attribute}=#{self.send(attribute)}"
        end.join(', ')
    end

  end
end
