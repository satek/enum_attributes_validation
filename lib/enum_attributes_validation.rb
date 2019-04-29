require 'enum_attributes_validation/version'
require 'active_support'
require 'active_record'

module EnumAttributesValidation
  extend ActiveSupport::Concern

  included do
    attr_writer :enum_invalid_attributes
    def enum_invalid_attributes
      @enum_invalid_attributes ||= {}
    end
    validate :check_enum_invalid_attributes

    private

      def check_enum_invalid_attributes
        if enum_invalid_attributes.present?
          enum_invalid_attributes.each do |key, opts|
            if opts[:message]
              self.errors.add(:base, opts[:message])
            else
              self.errors.add(key, :invalid_enum, value: opts[:value], valid_values: self.class.send(key.to_s.pluralize).keys.sort.join(', '), default: "value provided (#{opts[:value]}) is invalid")
            end
          end
        end
      end
  end

  class_methods do
    def validate_enum_attributes(*attributes, **opts)
      attributes.each do |attribute|
        attribute = attribute.to_s

        define_method "#{attribute}=" do |argument|
          if argument.nil?
            self[attribute] = nil
          else
            argument = argument.to_s
            if self.class.send(attribute.pluralize).keys.include?(argument)
              self[attribute] = argument
            else
              self.enum_invalid_attributes[attribute] = opts.merge(value: argument)
            end
          end
        end
      end
    end

    def validate_enum_attribute(*attributes)
      self.validate_enum_attributes(*attributes)
    end
  end
end

# include the extension in active record
ActiveRecord::Base.send(:include, EnumAttributesValidation)
