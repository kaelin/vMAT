#  namedCoercions.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/25/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require 'vMATCodeMonkey'

VMATCodeMonkey.new.named_coercions do |to| <<"EOS"
vMAT_Array *
vMAT_#{to}(vMAT_Array * matrix)
{
    return vMAT_coerce(matrix, @[ @"#{to}", @"-copy" ]);
}
EOS
end
