module KQL
  class Selector
    attr_reader :filter

    def initialize(filter)
      @filter = filter
    end

    def ==(other)
      return false unless other.class == Selector

      other.filter == filter
    end

    class Combined < Selector
      attr_reader :combinator, :selector

      def initialize(filter, combinator, selector)
        super(filter)
        @combinator = combinator
        @selector = selector
      end

      def ==(other)
        return false unless other.is_a?(Combined)

        other.filter == filter &&
          other.combinator == combinator &&
          other.selector == selector
      end
    end
  end
end
