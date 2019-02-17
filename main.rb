# -disasm add(a,b){return a+b;}
require 'http'
R /^-disasm\s+(?<args>[^\r\n]+)?(\r?\n(?<source>.+))?/m do |match:, **|
  D {
    args = match[:source] ? match[:args] : '-m32 -O'
    source = match[:source] || match[:args]
    filters = %i[labels intel comments directives demangle]
    json = JSON.parse HTTP.headers(Accept: 'application/json')
      .post('https://godbolt.org/api/compiler/cg82/compile', json: {
        source: source,
        options: {
          userArguments: args,
          filters: filters.map { |e| [e, true] }.to_h
        }
      }).to_s
    if json['code'] == 0
      json['asm'].map { |e| e['text'] }.join("\n")
    else
      json['stderr'].map { |e| e['text'].gsub(/\e\[(?:(?:\d+(?:;\d+)*)?m|K)/, '') }.join("\n")
    end
  }
end

# /deqrcode [pic]
require 'cgi'
require 'http'
require 'nokogiri'
R /\/deqrcode\s+\[CQ:image,file=(.+?)\]/ do |match:, **|
  D { Nokogiri::HTML(HTTP[:referer => 'https://zxing.org/w/decode.jspx'].get("https://zxing.org/w/decode?u=#{CGI.escape(File.read("data/image/#{match[1]}.cqimg")[/^url=(.*)$/, 1])}").to_s).css('#result pre').first.text }
end

# -win32const name
require 'tempfile'
R /^-win32const\s+(\S+)(?:\s+(\S+))?$/ do |match:, qq:, **|
  next unless P.user_has_privilege(qq, 'eval')
  x = LocalStorage.get("glob", ["cache", "win32const", match[1]])
  next x if x
  D {
    Tempfile.open(['a-', '.cpp'], 'tmp') do |f|
      f.write "#include<#{match[2]}>\n" if match[2]
      f.write "#define S(s) X(s)\n#define X(s) #s\n#include<windows.h>\n#include<d3d11.h>\n#include<bits/stdc++.h>\nint main(){puts(("" S(#{match[1]})));}"
      f.close
      Tempfile.open(['a-', '.exe'], 'tmp') do |o|
        o.close
        raw = `2>&1 g++ -w -O -m32 #{f.path.inspect} -o #{o.path.inspect} && #{o.path.inspect}`.encode("UTF-8", "GBK", replace: '?', invalid: :replace, undef: :replace, fallback: '?').chomp("\n")
        ans = if raw == match[1]
          open(f,'w'){|g|g.write "#include<windows.h>\n#include<d3d11.h>\n#include<cxxabi.h>\n#include<bits/stdc++.h>\nint main(){int status;char*name=abi::__cxa_demangle(typeid(#{match[1]}).name(),0,0,&status);puts(name);free(name);}"}
          `2>&1 g++ -w -O -m32 #{f.path.inspect} -o #{o.path.inspect} && #{o.path.inspect}`.encode("UTF-8", "GBK", replace: '?', invalid: :replace, undef: :replace, fallback: '?').chomp("\n")
        else
          raw
        end
        LocalStorage.set("glob", ["cache", "win32const", match[1]], ans)
        ans
      end
    end
  }
end
