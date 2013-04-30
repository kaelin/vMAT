class OptionSpecsLexer
rules
  \d+(\.\d*)            { [:number, text] }
  \w+:                  { [:syntax_hash_key, ":#{text[0, text.length - 1]} =>"] }
  \:\w+                 { [:symbol, text] }
  \w+                   { [:identifier, text] }
  \"(\\.|[^\\"])*\"     { [:string, text] }
  =>                    { [:rocket, text] }
  ,                     { [:comma, text] }
  {                     { [:open_curly, text] }
  }                     { [:close_curly, text] }
  \(                    { [:open_paren, text] }
  \)                    { [:close_paren, text] }
  \[                    { [:close_square, text] }
  \]                    { [:close_square, text] }
  \\\n                  { }
  \n                    { [:eol, text] }
  \s+                   { }
inner
  def enumerate_tokens
    Enumerator.new { |token|
      loop { token << next_token }
    }
  end
end
