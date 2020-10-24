# Wikimedia Microtask
## Results
To see the script output enter the results folder
## How it works
The script takes all the pages that are in the Module namespace and filters all the pages that are of documentation "/doc", of test "testcases" and all that have "User:", that way it keeps only code of the lua modules .


### Comments
The "contentmodel" filter was not used because it returned a 'polluted' lua script with HTML, like this:
```
{'title': 'Module:User:Mr. Stradivarius/BannerConvert',
 'pageid': 40071176,
 'revid': 565990756,
 'text': '<div class="mw-parser-output"><div lang="en" dir="ltr" class="mw-content-ltr">\n<div id="template-documentation" class="template-documentation iezoomfix">\n<div style="padding-bottom:3px;border-bottom:1px solid #aaa;margin-bottom:1ex">\n<span style="font-size:150%"><img alt="" src="//upload.wikimedia.org/wikipedia/commons/thumb/4/43/Test_Template_Info-Icon_-_Version_%282%29.svg/50px-Test_Template_Info-Icon_-_Version_%282%29.svg.png" decoding="async" width="50" height="22" srcset="//upload.wikimedia.org/wikipedia/commons/thumb/4/43/Test_Template_Info-Icon_-_Version_%282%29.svg/75px-Test_Template_Info-Icon_-_Version_%282%29.svg.png 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/4/43/Test_Template_Info-Icon_-_Version_%282%29.svg/100px-Test_Template_Info-Icon_-_Version_%282%29.svg.png 2x" data-file-width="1792" data-file-height="800" /> Module documentation</span><span class="mw-editsection-like plainlinks" id="doc_editlinks">&#91;<a class="external text" href="https://en.wikipedia.org/w/index.php?title=Module:User:Mr._Stradivarius/BannerConvert/doc&amp;action=edit&amp;preload=Template%3ADocumentation%2Fpreload-module-doc">create</a>&#93;</span></div>\n<div style="clear:both">\n</div></div><table id="documentation-meta-data" class="plainlinks fmbox fmbox-system" role="presentation" style="background-color: #ecfcf4"><tbody><tr><td class="mbox-text" style="font-style: italic">You might want to <a class="external text" href="https://en.wikipedia.org/w/index.php?title=Module:User:Mr._Stradivarius/BannerConvert/doc&amp;action=edit&amp;preload=Template%3ADocumentation%2Fpreload-module-doc">create</a> a documentation page for this <a href="/wiki/Wikipedia:Lua" title="Wikipedia:Lua">Scribunto module</a>.<br />Editors can experiment in this module\'s sandbox <small style="font-style: normal;">(<a class="external text" href="https://en.wikipedia.org/w/index.php?title=Module:User:Mr._Stradivarius/BannerConvert/sandbox&amp;action=edit&amp;preload=Template%3ADocumentation%2Fpreload-module-sandbox">create</a> &#124; <a class="external text" href="https://en.wikipedia.org/w/index.php?title=Module:User:Mr._Stradivarius/BannerConvert/sandbox&amp;preload=Module%3AUser%3AMr.+Stradivarius%2FBannerConvert&amp;action=edit&amp;summary=Create+sandbox+version+of+%5B%5BModule%3AUser%3AMr.+Stradivarius%2FBannerConvert%5D%5D">mirror</a>)</small> and testcases <small style="font-style: normal;">(<a class="external text" href="https://en.wikipedia.org/w/index.php?title=Module:User:Mr._Stradivarius/BannerConvert/testcases&amp;action=edit&amp;preload=Template%3ADocumentation%2Fpreload-module-testcases">create</a>)</small> pages.<br />Please add categories to the <a href="/w/index.php?title=Module:User:Mr._Stradivarius/BannerConvert/doc&amp;action=edit&amp;redlink=1" class="new" title="Module:User:Mr. Stradivarius/BannerConvert/doc (page does not exist)">/doc</a> subpage. <a href="/wiki/Special:PrefixIndex/Module:User:Mr._Stradivarius/BannerConvert/" title="Special:PrefixIndex/Module:User:Mr. Stradivarius/BannerConvert/">Subpages of this module</a>.</td></tr></tbody></table>\n</div>\n<!-- \nNewPP limit report\nParsed by mw2251\nCached time: 20201023233117\nCache expiry: 2592000\nDynamic content: false\nComplications: [vary‐revision‐sha1]\nCPU time usage: 0.040 seconds\nReal time usage: 0.054 seconds\nPreprocessor visited node count: 16/1000000\nPost‐expand include size: 1965/2097152 bytes\nTemplate argument size: 0/2097152 bytes\nHighest expansion depth: 2/40\nExpensive parser function count: 5/500\nUnstrip recursion depth: 0/20\nUnstrip post‐expand size: 0/5000000 bytes\nLua time usage: 0.017/10.000 seconds\nLua memory usage: 835 KB/50 MB\nNumber of Wikibase entities loaded: 0/400\n-->\n<!--\nTransclusion expansion time report (%,ms,calls,template)\n100.00%    0.000      1 -total\n-->\n<div class="mw-highlight"><pre><span></span><span class="kd">local</span> <span class="n">dts</span> <span class="o">=</span> .....><span class="p">,</span> <span class="s1">&#39;_image&#39;</span><span class="p">,</span> <span class="s1">&#39;_nested&#39;</span><span class="p">,</span> <span class="s1">&#39;_text&#39;</span><span class="p">,</span> <span class="s1">&#39;_quality&#39;</span><span class="p">,</span> <span class="s1">&#39;_main_cat&#39;</span><span class="p">,</span> <span class="s1">&#39;_assessment_cat&#39;</span> <span class="p">},</span> <span class="n">tfnums</span> <span class="p">)</span>\n    <span class="kr">do</span> <span class="kr">return</span> <span class="n">dts</span><span class="p">(</span> <span class="n">tf</span> <span class="p">)</span> <span class="kr">end</span> <span class="c1">-- for debugging</span>\n    \n    <span class="kd">local</span> <span class="n">rows</span> <span class="o">=</span> <span class="p">{}</span>\n    <span class="kr">for</span> <span class="n">i</span><span class="p">,</span> <span class="n">ptable</span> <span class="kr">in</span> <span class="nb">ipairs</span><span class="p">(</span> <span class="n">params</span> <span class="p">)</span> <span class="kr">do</span>\n        <span class="n">params</span><span class="p">[</span> <span class="n">i</span> <span class="p">][</span> <span class="mi">2</span> <span class="p">]</span> <span class="o">=</span> <span class="n">rebar</span><span class="p">(</span> <span class="n">ptable</span><span class="p">[</span> <span class="mi">2</span> <span class="p">]</span> <span class="p">)</span>\n        <span class="kr">if</span> <span class="nb">type</span><span class="p">(</span> <span class="n">ptable</span><span class="p">[</span> <span class="mi">1</span> <span class="p">]</span> <span class="p">)</span> <span class="o">==</span> <span class="s1">&#39;number&#39;</span> <span class="kr">then</span>\n            <span class="nb">table.insert</span><span class="p">(</span> <span class="n">rows</span><span class="p">,</span> <span class="n">mw</span><span class="p">.</span><span class="n">ustring</span><span class="p">.</span><span class="n">format</span><span class="p">(</span> <span class="s1">&#39;[%s] = &quot;%s&quot;&#39;</span><span class="p">,</span> <span class="n">mw</span><span class="p">.</span><span class="n">ustring</span><span class="p">.</span><span class="n">lower</span><span class="p">(</span> <span class="nb">tostring</span><span class="p">(</span> <span class="n">ptable</span><span class="p">[</span> <span class="mi">1</span> <span class="p">]</span>  <span class="p">)</span> <span class="p">),</span> <span class="n">ptable</span><span class="p">[</span> <span class="mi">2</span> <span class="p">]</span>  <span class="p">)</span> <span class="p">)</span>\n        <span class="kr">else</span>\n            <span class="nb">table.insert</span><span class="p">(</span> <span class="n">rows</span><span class="p">,</span> <span class="n">mw</span><span class="p">.</span><span class="n">ustring</span><span class="p">.</span><span class="n">format</span><span class="p">(</span> <span class="s1">&#39;%s = &quot;%s&quot;&#39;</span><span class="p">,</span> <span class="n">mw</span><span class="p">.</span><span class="n">ustring</span><span class="p">.</span><span class="n">lower</span><span class="p">(</span> <span class="n">ptable</span><span class="p">[</span> <span class="mi">1</span> <span class="p">]</span> <span class="p">),</span> <span class="n">ptable</span><span class="p">[</span> <span class="mi">2</span> <span class="p">]</span> <span class="p">)</span> <span class="p">)</span>\n        <span class="kr">end</span>\n    <span class="kr">end</span>\n    <span class="kr">return</span> <span class="n">mw</span><span class="p">.</span><span class="n">ustring</span><span class="p">.</span><span class="n">format</span><span class="p">(</span> <span class="s1">&#39;local banner = {</span><span class="se">\\n</span><span class="s1">    %s</span><span class="se">\\n</span><span class="s1">}&#39;</span><span class="p">,</span> <span class="nb">table.concat</span><span class="p">(</span> <span class="n">rows</span><span class="p">,</span> <span class="s1">&#39;,</span><span class="se">\\n</span><span class="s1">    &#39;</span> <span class="p">)</span> <span class="p">)</span>\n<span class="kr">end</span>\n\n<span class="kr">return</span> <span class="n">p</span>\n</pre></div>\n</div>'
```
However, `wikitext` returns the lua script without HTML tags, so I chose to use it. Like this:
```
{'title': 'Module:AFC submission catcheck/sandbox2',
 'pageid': 59702564, 
'wikitext': 'local p = {}\n\nlocal function removeFalsePositives(str)\n\tif not str then\n\t\treturn \'\'\n\tend\n\treturn mw.ustring.gsub(mw.ustring.gsub(str, "<!--.--->", ""), "<nowiki>.-</nowiki>", "")\nend\n\nfunction p.checkforcats(frame)\n    local t = mw.title.getCurrentTitle()\n    tc = t:getContent()\n    if tc == nil then \n        return ""\n    end\n    tc = removeFalsePositives(mw.ustring.gsub(tc,"%[%[Category:Articles created via the Article Wizard%]%]",""))\n    if mw.ustring.match(tc, "%[%[%s-[Cc]ategory:" ) == nil then\n        return ""\n    else\n        return "[[:Category:AfC submissions with categories]]"\n    end\nend\n\nfunction p.submitted(frame)\n\tif mw.ustring.find(removeFalsePositives(mw.title.getCurrentTitle():getContent()), \'{{AFC submission||\', 1, true) then\n\t\treturn frame.args[1]\n\telse\n\t\treturn frame.args[2]\n\tend\nend\n\nreturn p'}
```
## Usage
**if you don't want to wait for all API queries, just rename pages_backup.dat to pages.dat**.
(page.dat is a dict with title, pageid, and size of lua modules).

If there is a module folder it will look for the file size there
- With *pip*
```
pip3 install -r requirements.txt
python3 main.py
```
- With *pipenv*
```
pipenv run python main.py
```
## Output
A histogram (histogram.html) and a word cloud (World_Cloud_module_name.png) will be generated with the module names, it will also save the modules in the module folder.

Binary files will be generated with the information of the pages that will be used if they exist so that you don't need to consult the API again