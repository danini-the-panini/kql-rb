class KQL::Parser
  options no_result_var
  token IDENT
        STRING INTEGER FLOAT TRUE FALSE NULL
        LPAREN RPAREN
        LBRACKET RBRACKET
        COMMA
        VAL PROP
        TOP PROPS VALUES TAG NAME
        EQUALS NOT_EQUALS GTE GT LTE LT OR
        STARTS_WITH ENDS_WITH INCLUDES
        TILDE PLUS
        MAP

rule
  query : alternatives             { ::KQL::Query.new(val[0]) }
        | alternatives MAP mapping { ::KQL::Mapping.new(val[0], val[2]) }

  alternatives : selector                 { [val[0]] }
               | selector OR alternatives { [val[0], *val[2]] }

  selector : node_filter combinator selector { ::KQL::Selector::Combined.new(val[0], val[1], val[2]) }
           | node_filter selector            { ::KQL::Selector::Combined.new(val[0], ::KQL::Combinator::Child, val[1]) }
           | node_filter                     { ::KQL::Selector.new(val[0]) }

  combinator : GT    { ::KQL::Combinator::ImmediateChild }
             | TILDE { ::KQL::Combinator::Sibling }
             | PLUS  { ::KQL::Combinator::ImmediateSibling }

  node_filter : TOP                { ::KQL::Filter::Top }
              | IDENT              { ::KQL::Filter.new(node: val[0].value) }
              | IDENT matchers     { ::KQL::Filter.new(node: val[0].value, matchers: val[1]) }
              | tag IDENT          { ::KQL::Filter.new(node: val[1].value, tag: val[0]) }
              | tag IDENT matchers { ::KQL::Filter.new(node: val[1].value, tag: val[0], matchers: val[2]) }
              | tag matchers       { ::KQL::Filter.new(tag: val[0], matchers: val[1]) }
              | tag                { ::KQL::Filter.new(tag: val[0]) }
              | matchers           { ::KQL::Filter.new(matchers: val[0]) }

  tag : LPAREN IDENT RPAREN { ::KQL::Matcher::Tag.new(val[1].value) }
      | LPAREN RPAREN       { ::KQL::Matcher::AnyTag }

  matchers : matcher
           | matcher matchers

  matcher : LBRACKET matcher_accessor matcher_operator matcher_comparison RBRACKET { ::KQL::Matcher::Comparison.new(val[1], val[2], val[3]) }
          | LBRACKET matcher_accessor RBRACKET                                     { val[1] }
          | LBRACKET RBRACKET                                                      { ::KQL::Matcher::Any }

  matcher_accessor : IDENT { ::KQL::Accessor::Prop.new(val[2].value) }
                   | prop
                   | val
                   | NAME  { ::KQL::Accessor::Name }
                   | TAG   { ::KQL::Accessor::Tag }

  matcher_comparison : INTEGER             { ::KQL::Matcher::Value.new(val[0].value) }
                     | FLOAT               { ::KQL::Matcher::Value.new(val[0].value) }
                     | STRING              { ::KQL::Matcher::Value.new(val[0].value) }
                     | NULL                { ::KQL::Matcher::Value.new(nil) }
                     | TRUE                { ::KQL::Matcher::Value.new(true) }
                     | FALSE               { ::KQL::Matcher::Value.new(false) }
                     | LPAREN IDENT RPAREN { ::KQL::Matcher::Tag.new(val[1].value) }

  matcher_operator : EQUALS      { ::KQL::Operator::Equals }
                   | NOT_EQUALS  { ::KQL::Operator::NotEquals }
                   | GTE         { ::KQL::Operator::GreaterThanOrEqual }
                   | GT          { ::KQL::Operator::GreaterThan }
                   | LTE         { ::KQL::Operator::LessThanOrEqual }
                   | LT          { ::KQL::Operator::LessThan }
                   | STARTS_WITH { ::KQL::Operator::StartsWith }
                   | ENDS_WITH   { ::KQL::Operator::EndsWith }
                   | INCLUDES    { ::KQL::Operator::Includes }

  mapping : accessor                    { [val[0]] }
          | LPAREN mapping_tuple RPAREN { val[1] }

  mapping_tuple : accessor COMMA mapping_tuple { [val[0], *val[2]] }
                | accessor                     { [val[0]] }

  accessor : matcher_accessor
           | PROPS            { ::KQL::Accessor::Props }
           | VALUES           { ::KQL::Accessor::Values }

  prop : PROP LPAREN IDENT RPAREN { ::KQL::Accessor::Prop.new(val[2].value) }

  val : VAL LPAREN RPAREN         { ::KQL::Accessor::Val.new(nil) }
      | VAL LPAREN INTEGER RPAREN { ::KQL::Accessor::Val.new(val[2].value) }

---- inner
  def parse(str)
    @tokenizer = ::KQL::Tokenizer.new(str)
    do_parse
  end

  private

  def next_token
    @tokenizer.next_token
  end
