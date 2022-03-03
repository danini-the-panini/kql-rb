require 'test_helper'

class KQLTest < Minitest::Test
  def test_parse_query
    assert_kind_of(::KQL::Query, ::KQL.parse_query('a b'))
  end

  def test_query_document
    doc = ::KDL.parse_document('a')
    assert_equal([doc.nodes.first], ::KQL.query_document(doc, 'a'))
  end
end
