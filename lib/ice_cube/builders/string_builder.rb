module IceCube

  class StringBuilder

    attr_writer :base

    def initialize
      @types = {}
    end

    def piece(type, prefix = nil, suffix = nil)
      @types[type] ||= []
    end

    def to_s
      # Put the count at the end for better translation
      count = @types.delete(:count)
      @types.merge!({ count: count }) if count

      @types.each_with_object(@base || '') do |(type, segments), str|
        if f = self.class.formatter(type)
          str << ' ' << f.call(segments)
        else
          next if segments.empty?
          str << ' ' << self.class.sentence(segments)
        end
      end
    end

    def self.formatter(type)
      @formatters[type]
    end

    def self.register_formatter(type, &formatter)
      @formatters ||= {}
      @formatters[type] = formatter
    end

    module Helpers

      # influenced by ActiveSupport's to_sentence
      def sentence(array)
        *enum, final = array
        enumeration = enum.join(I18n.t 'ice_cube.array.words_connector')
        enumeration = enumeration.empty? ? nil : enumeration
        [enumeration, final].compact.join(I18n.t 'ice_cube.array.last_word_connector')
      end

      def connected_sentence(array, connector)
        sentence = self.sentence(array)

        if connector.is_a? Hash
          condition = Regexp.quote(connector[:condition])
          regexp = Regexp.new("^[#{condition}]")
          on_the = sentence !~ regexp ? connector[:default] : connector[:exception]
        else
          on_the = "#{connector} "
        end

        "#{on_the}#{sentence} "
      end

      def nice_number(number)
        literal_ordinal(number) || ordinalize(number)
      end

      def ordinalize(number)
        "#{number}#{ordinal(number)}"
      end

      def ordinal(number)
        ord = I18n.t("ice_cube.integer.ordinals")[number] ||
          I18n.t("ice_cube.integer.ordinals")[number % 10] ||
          I18n.t('ice_cube.integer.ordinals')[:default]

        number >= 0 ? ord : I18n.t("ice_cube.integer.negative", ordinal: ord)
      end

      def literal_ordinal(number)
        I18n.t("ice_cube.integer.literal_ordinals")[number]
      end

    end

    extend Helpers

  end

end
