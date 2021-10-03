module KQL
  class Combinator
    singleton :Child, Combinator do
    end

    singleton :ImmediateChild, Combinator do
    end

    singleton :Sibling, Combinator do
    end

    singleton :ImmediateSibling, Combinator do
    end
  end
end
