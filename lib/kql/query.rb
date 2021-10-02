module KQL
  class Query
    attr_reader :alternatives

    def initialize(alternatives)
      @alternatives = alternatives
    end

    def ==(other)
      return false unless other.is_a?(Query)

      other.alternatives == alternatives
    end
  end
end
