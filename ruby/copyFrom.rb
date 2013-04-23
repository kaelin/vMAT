#  copyFrom.rb
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require './vMATCodeMonkey'

VMATCodeMonkey.new(:pbcopy).coercions do |to, fm, to_t, fm_t| <<"EOS"
- (void)_copy_#{to}_from_#{fm}:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, #{to_t}, #{fm_t});
}
EOS
end
