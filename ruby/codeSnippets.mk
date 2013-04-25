#  codeSnippets.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require_relative 'vMATCodeMonkey'

print "    namedTypes = @{\n"
VMATCodeMonkey.new(:snippet).named_types do |type|
  "        @\"#{type}\": [NSNumber numberWithInt:mi#{type.upcase}]"
end
print "    };\n"
