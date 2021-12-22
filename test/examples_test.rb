require 'test_helper'

class ExamplesTest < Minitest::Test
  def setup
    @parser = ::KQL::Parser.new
    @document = ::KDL.parse_document <<~KDL
      package {
        name "foo"
        version "1.0.0"
        dependencies platform="windows" {
          winapi "1.0.0" path="./crates/my-winapi-fork"
        }
        dependencies {
          miette "2.0.0" dev=true
        }
      }
    KDL
  end

  def test_query
    assert_query_fetches('package name', @document.nodes.first.children.first)
    assert_query_fetches('top() > package name', @document.nodes.first.children.first)
    assert_query_fetches('dependencies', [@document.nodes.first.children[2],
                                          @document.nodes.first.children[3]])
    assert_query_fetches('dependencies[platform]', @document.nodes.first.children[2])
    assert_query_fetches('dependencies[prop(platform)]', @document.nodes.first.children[2])
    assert_query_fetches('dependencies > []', [@document.nodes.first.children[2].children.first,
                                               @document.nodes.first.children[3].children.first])
  end

  def test_map
    assert_query_fetches('package name => val()', 'foo')
    assert_query_fetches('dependencies[platform] => platform', 'windows')
    assert_query_fetches('dependencies > [] => (name(), val(), path)', [['winapi', '1.0.0', './crates/my-winapi-fork'],
                                                                        ['miette', '2.0.0', nil]])
    assert_query_fetches('dependencies > [] => (name(), values(), props())', [['winapi', ['1.0.0'], { 'path' => './crates/my-winapi-fork' }],
                                                                              ['miette', ['2.0.0'], { 'dev' => true }]])
  end

  private
  attr_reader :document
end

