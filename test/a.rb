$procs = {}

def R(cond, &blk)
  $procs[cond] = blk
end

def T(input)
  $procs.each do |cond, blk|
    m = cond.match input
    puts blk.call(match: m, qq: 123456789) if m
  end
end

:eval
# -win32const name
require 'tempfile'
R /^-win32const\s+(\w+)$/ do |match:, **|
  Tempfile.open(['a-', '.c'], 'tmp') do |f|
    f.write "#define S(s) X(s)\n#define X(s) #s\n#include<windows.h>\n#include<d3d11.h>\nmain(){puts(("" S(#{match[1]})));}"
    f.close
    Tempfile.open(['a-', '.exe'], 'tmp') do |o|
      o.close
      raw = `2>&1 gcc -w -O -m32 #{f.path.inspect} -o #{o.path.inspect} && #{o.path.inspect}`.encode("UTF-8", "GBK", replace: '?', invalid: :replace, undef: :replace, fallback: '?').chomp("\n")
      raw
    end
  end
end

T <<-EOS
-win32const MB_YESNO
EOS
