#  arrayTypeOptions.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require 'vMATCodeMonkey'

VMATCodeMonkey.new.options_processor <<EOS
  array_type  default: :double
EOS
