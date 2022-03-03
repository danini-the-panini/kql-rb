module KQL
  class Combinator
    singleton :Child, Combinator do
      def execute(context, selector)
        selector.execute(Query::Context.new(context.top, context.children))
      end
    end

    singleton :ImmediateChild, Combinator do
      def execute(context, selector)
        selector.execute(Query::Context.new(context.top, context.children(stop: true)))
      end
    end

    singleton :Sibling, Combinator do
      def execute(context, selector)
        selected_nodes = context.selected_nodes
                                .flat_map { |node|
                                  node.siblings
                                      .each_with_index
                                      .select { |n, i| i > node.index }
                                      .map { |n, i| Query::SelectedNode.new(n, node.node.children, i, stop: true) }
                                }
        selector.execute(Query::Context.new(context.top, selected_nodes))
      end
    end

    singleton :ImmediateSibling, Combinator do
      def execute(context, selector)
        selected_nodes = context.selected_nodes
                                .flat_map { |node|
                                  node.siblings
                                      .each_with_index
                                      .select { |n, i| i == node.index + 1 }
                                      .map { |n, i| Query::SelectedNode.new(n, node.node.children, i, stop: true) }
                                }
        selector.execute(Query::Context.new(context.top, selected_nodes))
      end
    end
  end
end
