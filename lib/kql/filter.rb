module KQL
  class Filter
    attr_reader :node, :tag, :matchers

    def initialize(node: nil, tag: nil, matchers: [])
      @node = node
      @tag = tag
      @matchers = matchers
    end

    def ==(other)
      return false unless other.is_a?(Filter)

      other.node == node &&
        other.tag == tag &&
        other.matchers == matchers
    end

    class Top < Filter
    end
  end
end
