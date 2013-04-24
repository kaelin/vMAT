#  arrayTypeOptions.rb
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require './vMATCodeMonkey'

VMATCodeMonkey.new(:print).options_processor <<EOS
  :arrayType  default: 'double'
EOS

VMATCodeMonkey.new(:print).options_processor <<EOS
  -cutoff:    flag: set('useCutoff', true), arg: vector('double')
  -depth:     flag: set('useInconsistent', true), arg: :double, default: 2.0
  -maxclust:  flag: set('useCutoff', false), arg: vector('index')
EOS
