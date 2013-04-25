#  arrayTypeOptions.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require_relative 'vMATCodeMonkey'

VMATCodeMonkey.new.options_processor <<EOS
  array_type  default: :double
EOS

VMATCodeMonkey.new.options_processor <<EOS, :static
  -cutoff:    flag: set(:useCutoff, true), arg: vector(:double)
  -depth:     flag: set(:useInconsistent, true), arg: :double, default: 2.0
  -maxclust:  flag: set(:useCutoff, false), arg: vector(:index)
EOS
