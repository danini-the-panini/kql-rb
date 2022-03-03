require 'test_helper'

class QueryTest < Minitest::Test
  attr_accessor :doc

  def setup
    @parser = ::KQL::Parser.new
  end

  def test_selectors
    @doc = parse <<~KDL
    a n=1 {
      b n=2
      c n=3 {
        b n=4
      }
    }
    b n=5
    b n=6
    KDL

    assert_query_fetches('a', doc.nodes.first)
    assert_query_fetches('a > b', doc.nodes.first.children.first)
    assert_query_fetches('a b', [doc.nodes.first.children.first,
                                 doc.nodes.first.children[1].children.first])
    assert_query_fetches('a b || a c', [doc.nodes.first.children.first,
                                        doc.nodes.first.children[1].children.first,
                                        doc.nodes.first.children[1]])
    assert_query_fetches('a + b', doc.nodes[1])
    assert_query_fetches('b + b', doc.nodes[2])
    assert_query_fetches('b + c', doc.nodes.first.children[1])
    assert_query_fetches('a ~ b', [doc.nodes[1], doc.nodes[2]])
    assert_query_fetches('[]', all_nodes)
  end

  def test_immediate_sibling
    @doc = parse <<~KDL
    a {
      foo "bar"
      qux "baz"
      b norf="wat" {
        c
      }
      b {
        c d=2
      }
    }
    KDL

    assert_query_fetches('b + b', doc.nodes.first.children[3])
  end

  def test_matchers
    @doc = parse <<~KDL
    (foo)a prop=true
    (bar)b 1 foo=true
    c 1 2 prop=false
    KDL

    assert_query_fetches('top()', doc.nodes)
    assert_query_fetches('top() > []', doc.nodes)
    assert_query_fetches('(foo)', doc.nodes.first)
    assert_query_fetches('()', [doc.nodes.first, doc.nodes[1]])
    assert_query_fetches('[val()]', [doc.nodes[1], doc.nodes[2]])
    assert_query_fetches('[val(1)]', doc.nodes[2])
    assert_query_fetches('[prop(foo)]', doc.nodes[1])
    assert_query_fetches('[prop]', [doc.nodes.first, doc.nodes[2]])
  end

  def test_matcher_operators
    @doc = parse <<~KDL
    a 1
    b 2
    c name=1
    hi
    (hi)d
    KDL

    assert_query_fetches('[val() = 1]', doc.nodes.first)
    assert_query_fetches('[prop(name) = 1]', doc.nodes[2])
    assert_query_fetches('[name = 1]', doc.nodes[2])
    assert_query_fetches('[name() = "hi"]', doc.nodes[3])
    assert_query_fetches('[tag() = "hi"]', doc.nodes[4])
    assert_query_fetches('[val() != 1]', doc.nodes[1])
  end

  def test_matcher_comparisons
    @doc = parse <<~KDL
    a 0
    b 1
    c 2
    KDL

    assert_query_fetches('[val() > 1]', doc.nodes[2])
    assert_query_fetches('[val() >= 1]', [doc.nodes[1], doc.nodes[2]])
    assert_query_fetches('[val() < 1]', doc.nodes.first)
    assert_query_fetches('[val() <= 1]', [doc.nodes.first, doc.nodes[1]])
  end

  def test_string_matchers
    @doc = parse <<~KDL
    a "foo bar"
    b "bar foo"
    c "bar foo baz"
    d "bar"
    KDL

    assert_query_fetches('[val() ^= "foo"]', doc.nodes.first)
    assert_query_fetches('[val() $= "foo"]', doc.nodes[1])
    assert_query_fetches('[val() *= "foo"]', [doc.nodes.first, doc.nodes[1], doc.nodes[2]])
  end

  def test_tag_matchers
    @doc = parse <<~KDL
    a (foo)1
    b 1 (foo)2
    c name=(foo)"asdf"
    KDL

    assert_query_fetches('[val() = (foo)]', doc.nodes.first)
    assert_query_fetches('[val(1) = (foo)]', doc.nodes[1])
    assert_query_fetches('[prop(name) = (foo)]', doc.nodes[2])
    assert_query_fetches('[name = (foo)]', doc.nodes[2])
  end

  private

  def parse(kdl)
    ::KDL.parse_document(kdl)
  end
  
  def document
    @doc
  end

  def all_nodes(nodes = document.nodes)
    nodes.flat_map do |node|
      [node, *all_nodes(node.children)]
    end
  end
end
