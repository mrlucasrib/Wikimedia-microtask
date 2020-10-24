-- This module implements {{su}}.

local p = {}

function p.main(frame)
	-- Use arguments from the parent frame only, and remove any blank arguments.
	-- We don't need to trim whitespace from any arguments, as this module only
	-- uses named arguments, and whitespace is trimmed from them automatically. 
	local origArgs = frame:getParent().args
	local args = {}
	for k, v in pairs(origArgs) do
		if v ~= '' then
			args[k] = v
		end
	end

	-- Define the variables to pass to luaMain.
	local sup = args.p
	local sub = args.b
	local options = {
		align = args.a,
		fontSize = args.w,
		lineHeight = args.lh,
		verticalAlign = args.va
	}
	return p._main(sup, sub, options)
end

function p._main(sup, sub, options)
	options = options or {}
	local span = mw.html.create('span')

	-- Set the styles.
	span:css{
		['display']        = 'inline-block',
		['margin-bottom']  = '-0.3em',
		['vertical-align'] = options.verticalAlign or sub and '-0.4em' or '0.8em',
		['line-height']    = options.lineHeight or '1.2em'
	}
	if options.fontSize == 'f' or options.fontSize == 'fixed' then
		span:css{
			['font-family'] = 'monospace',
			['font-size']   = '80%'
		}
	else
		span:css('font-size', options.fontSize or '80%')
	end
	if options.align == 'r' or options.align == 'right' then
		span:css('text-align', 'right')
	elseif options.align == 'c' or options.align == 'center' then
		span:css('text-align', 'center')
	else
		span:css('text-align', 'left')
	end

	-- Add the wikitext.
	span
		:tag('sup')
			:css('font-size', 'inherit')
			:css('line-height', 'inherit')
			:css('vertical-align', 'baseline')
			:wikitext(sup)
			:done()
		:tag('br', {selfClosing = true}):done()
		:tag('sub')
			:css('font-size', 'inherit')
			:css('line-height', 'inherit')
			:css('vertical-align', 'baseline')
			:wikitext(sub)
	
	return tostring(span)
end

return p