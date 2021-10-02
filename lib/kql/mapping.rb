module KQL
  class Mapping
    attr_accessor :alternatives, :mapping

    def initialize(alternatives, mapping)
      @alternatives = alternatives
      @mapping = mapping
    end

    def ==(other)
      return false unless other.is_a?(Mapping)

      other.alternatives == alternatives &&
        other.mapping = mapping
    end
  end
end
