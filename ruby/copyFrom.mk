#  copyFrom.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require_relative 'vMATCodeMonkey'

VMATCodeMonkey.new.coercions do |to, fm, to_t, fm_t| <<"EOS"
- (void)_copy_#{to}_from_#{fm}:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, #{to_t}, #{fm_t});
}
EOS
end
