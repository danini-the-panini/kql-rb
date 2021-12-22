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

    def execute(document)
      alternatives.flat_map do |alt|
        alt.execute(TopContext.new(document))
           .nodes
           .uniq { |n| n.__id__ }
      end
    end

    private

    class Context
      attr_accessor :selected_nodes

      def initialize(selected_nodes)
        @selected_nodes = selected_nodes
      end

      def nodes
        selected_nodes.map(&:node)
      end

      def children(**kwargs)
        nodes.flat_map do |node|
          node.children
              .each_with_index
              .map { |n, i| Query::SelectedNode.new(n, node.children, i, **kwargs) }
        end
      end

      def top?
        false
      end
    end

    class TopContext < Context
      attr_accessor :document

      def initialize(document)
        @document = document
        super(children)
      end

      def children(**kwargs)
        document.nodes.each_with_index.map { |n, i| Query::SelectedNode.new(n, document.nodes, i, **kwargs) }
      end

      def top?
        true
      end
    end

    class SelectedNode
      attr_accessor :node, :siblings, :index, :stop

      def initialize(node, siblings, index, stop: false)
        @node = node
        @siblings = siblings
        @index = index
        @stop = stop
      end
    end
  end
end
