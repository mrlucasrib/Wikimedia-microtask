local p = {}
p.Hello = 'Hello'
function p.calc(num)
   return num
end
function p.sum_mult(num)
   return num + num, num * num
end
function p.mtable(num)
   return {num, num+1}
end
return p