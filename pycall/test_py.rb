#+begin_src ruby
require 'pycall/import'
include PyCall::Import

pyimport :math
p math.sin(math.pi / 4) - Math.sin(Math::PI / 4)   # => 0.0

#+end_src
