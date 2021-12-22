require 'test_helper'

class MappingTest < Minitest::Test
  def setup
    @parser = ::KQL::Parser.new
  end

  def test_name
    @doc = parse <<~KDL
    a
    b
    KDL

    assert_query_fetches('a => name()', 'a')
    assert_query_fetches('[] => name()', ['a', 'b'])
  end

  def test_val
    @doc = parse <<~KDL
    a 1 2 3 4
    b "x" "y" "z"
    c
    KDL

    assert_query_fetches('a => val()', 1)
    assert_query_fetches('b => val(2)', 'z')
    assert_query_fetches('[] => val(2)', [3, 'z', nil])
  end

  def test_prop
    @doc = parse <<~KDL
    a foo=1
    b foo="x"
    c
    KDL

    assert_query_fetches('a => prop(foo)', 1)
    assert_query_fetches('a => foo', 1)
    assert_query_fetches('c => foo', nil)
    assert_query_fetches('[] => foo', [1, 'x', nil])
  end

  def test_props
    @doc = parse <<~KDL
    a foo=1 bar=2
    b foo="x" bar="y"
    c
    KDL

    assert_query_fetches('a => props()', { 'foo' => 1, 'bar' => 2 })
    assert_query_fetches('b => props()', { 'foo' => 'x', 'bar' => 'y' })
    assert_query_fetches('c => props()', {})
    assert_query_fetches('[] => props()', [{ 'foo' => 1, 'bar' => 2 },
                                           { 'foo' => 'x', 'bar' => 'y' },
                                           {}])
  end

  def test_values
    @doc = parse <<~KDL
    a 1 2 3 4
    b "x" "y" "z"
    c
    KDL

    assert_query_fetches('a => values()', [1, 2, 3, 4])
    assert_query_fetches('b => values()', ['x', 'y', 'z'])
    assert_query_fetches('c => values()', [])
    assert_query_fetches('[] => values()', [[1, 2, 3, 4], ['x', 'y', 'z'], []])
  end

  def test_tag
    @doc = parse <<~KDL
    (foo)a
    (bar)b
    c
    KDL

    assert_query_fetches('a => tag()', 'foo')
    assert_query_fetches('b => tag()', 'bar')
    assert_query_fetches('c => tag()', nil)
    assert_query_fetches('[] => tag()', ['foo', 'bar', nil])
  end

  def test_tuple
    @doc = parse <<~KDL
    (foo)a 1 baz=2
    (bar)b 3
    c baz=4
    KDL

    assert_query_fetches('a => (tag(), name(), val(0), baz)', ['foo', 'a', 1, 2])
    assert_query_fetches('b => (tag(), name(), val(0), baz)', ['bar', 'b', 3, nil])
    assert_query_fetches('c => (tag(), name(), val(0), baz)', [nil, 'c', nil, 4])
    assert_query_fetches('[] => (tag(), name(), val(0), baz)', [['foo', 'a', 1, 2],
                                                                ['bar', 'b', 3, nil],
                                                                [nil, 'c', nil, 4]])
  end

  private

  def parse(kdl)
    ::KDL.parse_document(kdl)
  end

  def document
    @doc
  end
end
