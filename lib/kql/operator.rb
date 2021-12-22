module KQL
  class Operator
    singleton :Equals, Operator do
      def execute(a, b)
        a == b
      end
    end

    singleton :NotEquals, Operator do
      def execute(a, b)
        a != b
      end
    end

    singleton :GreaterThanOrEqual, Operator do
      def execute(a, b)
        a >= b
      end
    end

    singleton :GreaterThan, Operator do
      def execute(a, b)
        a > b
      end
    end

    singleton :LessThanOrEqual, Operator do
      def execute(a, b)
        a <= b
      end
    end

    singleton :LessThan, Operator do
      def execute(a, b)
        a < b
      end
    end

    singleton :StartsWith, Operator do
      def execute(a, b)
        a.start_with?(b)
      end
    end

    singleton :EndsWith, Operator do
      def execute(a, b)
        a.end_with?(b)
      end
    end

    singleton :Includes, Operator do
      def execute(a, b)
        a.include?(b)
      end
    end
  end
end
