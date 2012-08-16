module Toy
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      include Identity
      if ActiveSupport::VERSION::MAJOR == 3 && ActiveSupport::VERSION::MINOR > 1 # ActiveSupport 3.2
        attribute_method_suffix('=', '?')
      else # ActiveSupport 3.0, 3.1
        attribute_method_suffix('', '=', '?')
      end
    end

    module ClassMethods
      def attributes
        @attributes ||= {}
      end

      def defaulted_attributes
        attributes.values.select(&:default?)
      end

      def attribute(key, type, options = {})
        attr = Attribute.new(self, key, type, options)
        define_attribute_methods [key]
        attr
      end

      def attribute?(key)
        attributes.has_key?(key.to_s)
      end
    end

    def initialize(attrs={})
      initialize_attributes
      self.attributes = attrs
      write_attribute :id, self.class.next_key(self) unless id?
    end

    def id
      read_attribute(:id)
    end

    def attributes
      @attributes
    end

    def persisted_attributes
      {}.tap do |attrs|
        self.class.attributes.except('id').each do |name, attribute|
          next if attribute.virtual?
          attrs[attribute.persisted_name] = attribute.to_store(read_attribute(attribute.name))
        end
      end
    end

    def attributes=(attrs, *)
      return if attrs.nil?
      attrs.each do |key, value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
          set_will_change(key)
        elsif attribute_method?(key)
          write_attribute(key, value)
          set_will_change(key)
        end
      end
    end

    def set_will_change(key)
      attr = self.class.attributes[key.to_s]
      if attr
        unless (attr.type.is_a?(Array) || attr.type.is_a?(Toy::Object))
          send("#{key}_will_change!")
        end
      end
    end

    def [](key)
      read_attribute(key)
    end

    def []=(key, value)
      write_attribute(key, value)
    end

    private

    def read_attribute(key)
      @attributes[key.to_s]
    end

    def write_attribute(key, value)
      key = key.to_s
      attribute = self.class.attributes.fetch(key) {
        raise AttributeNotDefined, "#{self.class} does not have attribute #{key}"
      }
      @attributes[key.to_s] = attribute.from_store(value)
    end

    def attribute_method?(key)
      self.class.attribute?(key)
    end

    def attribute(key)
      read_attribute(key)
    end

    def attribute=(key, value)
      write_attribute(key, value)
    end

    def attribute?(key)
      read_attribute(key).present?
    end

    def initialize_attributes
      @attributes ||= {}
      self.class.defaulted_attributes.each do |attribute|
        @attributes[attribute.name.to_s] = attribute.default
      end
    end
  end
end
