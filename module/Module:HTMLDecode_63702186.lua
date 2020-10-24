local i = {};

function i.HTMLDecode(frame)
    return mw.text.decode(frame.args["text"]);
end

return i;