# -disasm add(a,b){return a+b;}
# @require tdmgcc, objdump
require 'tempfile'
R /^-disasm\s+(.+)$/m do |match:, **|
  Tempfile.open(['a-', '.c'], 'tmp') do |f|
    f.write match[1] + 'main(){}'
    f.close
    Tempfile.open(['a-', '.o'], 'tmp') do |o|
      o.close
      raw = `2>&1 gcc -c -g -w -O2 -m32 #{f.path.inspect} -o #{o.path.inspect} && objdump -S -M intel #{o.path.inspect}`.encode("UTF-8", "GBK", replace: '?', invalid: :replace, undef: :replace, fallback: '?').chomp("\n")
      m = raw.match /^Disassembly of section \.text:\s+(.+?)\n\S+?\s\<_main\>/m
      m ? m[1].gsub("\n\n", "\n").chomp : raw
    end
  end
end

# /deqrcode [pic]
require 'mechanize'
require 'nokogiri'
Process::RLIMIT_NOFILE = 7 if Gem.win_platform?
R /\/deqrcode\s+\[CQ:image,file=(.+?)\]/ do |match:, **|
  D { Nokogiri::HTML(Mechanize.new.get('https://zxing.org/w/decode.jspx').form_with(method: 'GET'){ |c| c.fields.first.value = File.read("data/image/#{match[1]}.cqimg")[/^url=(.*)$/, 1] }.submit.body).css('#result pre').first.text }
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
