require 'test_helper'

class CasesTest < Minitest::Test
  def self.cases
    @cases ||= ::KDL.parse_document(File.read('test/cases/package.kdl'))
  end

  def self.document
    @document ||= ::KDL::Document.new(cases.nodes.find { |n| n.name == 'input' }.children)
  end

  def self.queries
    @queries ||= cases.nodes.select { |n| n.name == 'query' }
  end

  def setup
    @parser = ::KQL::Parser.new
  end

  queries.each do |q|
    query = q.arguments.first.value
    output = q.children

    define_method("test_#{query}") do
      assert_query_fetches(query, output)
    end
  end

  private

  def document
    self.class.document
  end
end
