-- Computes the mollar mass from a simple chemical formula
--    like H2O, NH3, CuSO4, Si(OH)4, 2H2O
--
local c = {} -- module's table
	
local am = { -- Atomic Mass table (extracted from .svg)
	H=1.00794; He=4.002602;
	Li=6.941; Be=9.012182; B=10.811; C=12.0107; N=14.00674; O=15.9994; F=18.9984032; Ne=20.1797;
	Na=22.98976928; Mg=24.3050; Al=26.9815386; Si=28.0855; P=30.973762; S=32.066; Cl=35.4527; Ar=39.948;
	K=39.0983; Ca=40.078; Sc=44.955912; Ti=47.867; V=50.9415; Cr=51.9961; Mn=54.938045; Fe=55.845; Co=58.933195; Ni=58.6934; Cu=63.546; Zn=65.39; Ga=69.723; Ge=72.61; As=74.92160; Se=78.96; Br=79.904; Kr=83.80;
	Rb=85.4678; Sr=87.62; Y=88.90585; Zr=91.224; Nb=92.90638; Mo=95.94; Tc=97.9072; Ru=101.07; Rh=102.90550; Pd=106.42; Ag=107.8682; Cd=112.411; In=114.818; Sn=118.710; Sb=121.760; Te=127.60; I=126.90447; Xe=131.29;
	Cs=132.9054519; Ba=137.327; Hf=178.49; Ta=180.94788; W=183.84; Re=186.207; Os=190.23; Ir=192.217; Pt=195.084; Au=196.966569; Hg=200.59; Tl=204.3833; Pb=207.2; Bi=208.98040; Po=208.9824; At=209.9871; Rn=222.0176;
		La=138.90547; Ce=140.116; Pr=140.90765; Nd=144.242; Pm=144.9127; Sm=150.36; Eu=151.964; Gd=157.25; Tb=158.92535; Dy=162.500; Ho=164.93032; Er=167.259; Tm=168.93421; Yb=173.04; Lu=174.967;
	Fr=223.0197; Ra=226.0254; Rf=263.1125; Db=262.1144; Sg=266.1219; Bh=264.1247; Hs=269.1341; Mt=268.1388; Ds=272.1463; Rg=272.1535; Cn=277.0; Nh=284.0; Fl=289.0; Mc=288.0; Lv=292.0; Ts=292.0; Og=294.0;
		Ac=227.0277; Th=232.03806; Pa=231.03588; U=238.02891; Np=237.0482; Pu=244.0642; Am=243.0614; Cm=247.0703; Bk=247.0703; Cf=251.0796; Es=252.0830; Fm=257.0951; Md=258.0984; No=259.1011; Lr=262.110;
}
	
local T_ELEM   = 0 -- token types
local T_NUM    = 1
local T_O      = 2 -- open '('
local T_C      = 3 -- close ')'
local T_MIDDOT = 4 -- hydration delimiter
local T_SPACE  = 5 -- whitespace
local T_WATER  = 6 -- crystallization water '•xH2O'
	
function item(f) -- (iterator) returns one token (type, value) at a time from the formula 'f'
	local i = 1
	return function ()
		local t, x = nil, nil
		if i <= f:len() then
			x = f:match('^%u%l*', i); t = T_ELEM;  -- matching elem (C, O, Ba, Na,...)
			if not x then x = f:match('^[%d.]+', i); t = T_NUM; end -- matching number
			if not x then x = f:match('^%(', i); t = T_O; end    -- matching '('
			if not x then x = f:match('^%)', i); t = T_C; end    -- matching ')'
																	if not x then x = f:match('^•[%d.]*H2O', i); t = T_WATER; end -- matching '•xH2O' x number, optional
			if not x then x = f:match('^•', i); t = T_MIDDOT; end    -- matching '•'
			if not x then x = f:match('^%s+', i); t = T_SPACE; end    -- matching whitespace
			if x then i = i + x:len(); else error("Invalid character in formula beginning at '"..f:sub(i).."'") end
		end
		return t, x
	end
end

function c.mm(frame) -- molar mass of the formula 'f'
	local f = frame.args[1]
	local sum, cur = {0}, {0}  -- stacks to handle '()' ; 'cur' awaits to be multiplied (or not)
	local t, x
	for t, x in item(f) do 
		if t == T_ELEM then if not am[x] then error("Unknown element : "..x) end
		sum[#sum] = sum[#sum] + cur[#cur]; cur[#cur] = am[x]
		elseif t == T_NUM  then sum[#sum] = sum[#sum] + cur[#cur] * tonumber(x); cur[#cur] = 0
		elseif t == T_O    then sum[#sum] = sum[#sum] + cur[#cur]; cur[#cur] = 0;sum[#sum+1] = 0; cur[#cur+1] = 0 -- push
		elseif t == T_C    then if #sum < 2 then error("Too many ')' in "..f) end
			sum[#sum] = sum[#sum] + cur[#cur]; cur[#cur-1] = sum[#sum]; sum[#sum], cur[#cur] = nil, nil -- pop
		elseif t == T_WATER then 
			if string.match(x, '•%d+') then
				sum[#sum] = sum[#sum] + ((2*am.H + am.O) * tonumber(string.match(x, '[%d.]+')))
			else
				-- sum[#sum] = sum[#sum] + (2*am.H + am.O)
			end
		elseif t == T_MIDDOT then error("Hydration syntax (•) not yet supported")
		elseif t ~= T_SPACE then error('???') end -- ignore whitespace
	end
	if #sum > 1 then error("Too many '(' in "..f) end

	-- check leading number (2XyZ)
	if string.match(f, '^[%d.]+') then 
		return (sum[1] + cur[1]) * tonumber(string.match(f, '^[%d.]+'))
	else
		return sum[1] + cur[1]
	end
end
	
--[[ tests -------------
c.frame = {}
c.frame.args = {}
	
function pm(f)
	c.frame.args[1] = f
	print('The molar mass of '..f..' is '..c.mm(c.frame))
end
	
pm("NaCl")
pm("NaOH")
pm("CaCO3")
pm("H2SO4")
pm("C10H8")
pm("CO2")
pm("Mo")
pm("HCl")
pm("Si(OH)4")
pm("CuSO4(H20)5")
--------------- --]]
	
return c -- exports c.mm()