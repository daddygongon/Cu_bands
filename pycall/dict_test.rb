require 'pycall/import'
include PyCall::Import


tmp =PyCall::Dict.new({zero: 0, one: 1, two: 2})
p arg1 = PyCall::Dict.({'Cu': PyCall::Tuple.(["s", "p", "d"])})
tmp_h = tmp.to_h
tmp_h.each do |key, val|
  p key
  p val
end
