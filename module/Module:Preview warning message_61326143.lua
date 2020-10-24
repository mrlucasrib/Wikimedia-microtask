local p = {};

function p.main(arguments)
	frame = mw.getCurrentFrame()
	return
	frame:extensionTag{ name = 'templatestyles', args = { src = 'Module:Preview warning message/styles.css'} } ..
	frame:expandTemplate{ name = 'hatnote', args = { arguments[1], extraclasses = 'warninghatnote'..(arguments.extraclasses or '') } }
end

return p