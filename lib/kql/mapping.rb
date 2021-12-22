require_relative './query'

module KQL
  class Mapping < Query
    attr_accessor :mapping

    def initialize(alternatives, mapping)
      super(alternatives)
      @mapping = mapping
    end

    def execute(document)
      nodes = super
      nodes.map { |node| mapping.execute(node) }
    end

    def ==(other)
      return false unless other.is_a?(Mapping)

      super(other) && other.mapping = mapping
    end
  end
end
