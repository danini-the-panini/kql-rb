class KQL::Parser
  options no_result_var
  token IDENT
        STRING INTEGER FLOAT TRUE FALSE NULL
        LPAREN RPAREN
        LBRACKET RBRACKET
        COMMA
        VAL PROP
        TOP PROPS VALUES TAG
        EQUALS NOT_EQUALS GTE GT LTE LE OR
        STARTS_WITH ENDS_WITH INCLUDES

rule
  query : alternatives
        | alternatives MAP mapping

  alternatives : selector
               | selector OR alternatives

  selector : node_filter combinator selector
           | node_filter selector
           | node_filter

  combinator : GT
             | TILDE
             | PLUS

  node_filter : TOP
              | IDENT
              | IDENT matchers
              | tag IDENT
              | tag IDENT matchers
              | tag matchers

  tag : LPAREN IDENT RPAREN
      | LPAREN RPAREN

  matchers : matcher
           | matcher matchers

  matcher : matcher_accessor matcher_operator matcher_comparison
          | matcher_accessor

  matcher_accessor : IDENT
                   | prop
                   | val
                   | NAME
                   | TAG

  matcher_comparison : INTEGER | FLOAT | STRING | NULL | TRUE | FALSE | LPAREN IDENT RPAREN

  matcher_operator : EQUALS
                   | NOT_EQUALS
                   | GTE
                   | GT
                   | LTE
                   | LT
                   | STARTS_WITH
                   | ENDS_WITH
                   | INCLUDES

  mapping : accessor
          | LPAREN mapping_tuple RPAREN

  mapping_tuple : accessor COMMA mapping_tuple
                | accessor

  accessor : matcher_accessor
           | PROPS
           | VALUES

  prop : PROP LPAREN RPAREN
       | PROP LPAREN IDENT RPAREN

  val : VAL LPAREN RPAREN
      | VAL LPAREN INTEGER RPAREN

  none: { nil }

---- inner
  def parse(str)
    @tokenizer = ::KQL::Tokenizer.new(str)
    do_parse
  end

  private

  def next_token
    @tokenizer.next_token
  end
