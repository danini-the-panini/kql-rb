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

    def execute(context)
      selected_nodes = []

      context.selected_nodes.flat_map do |n|
        selected_nodes << n if match?(n.node)
        selected_nodes += filter_nodes(n.node.children, n.node) unless n.stop
      end

      Query::Context.new(context.top, selected_nodes)
    end

    singleton :Top, Filter do
      def initialize
        super
      end

      def execute(context)
        context.top
      end
    end

    private

    def filter_nodes(nodes, parent = nil)
      filtered = nodes.each_with_index
                      .select { |n, _| match?(n) }
                      .map { |n, i| Query::SelectedNode.new(n, parent.children, i) }
      children = nodes.flat_map { |n| filter_nodes(n.children, n) }
      filtered + children
    end

    def match?(n)
      return false unless node.nil? || node == n.name
      return false unless tag.nil? || tag.match?(n)
      return matchers.all? { |m| m.match?(n) } unless matchers.empty?
      true
    end
  end
end
