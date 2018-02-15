# @require tdmgcc, objdump
require 'tempfile'
R /^-disasm\s*?\n(.+)$/m do |match:, **|
  Tempfile.open(['a-', '.c'], 'tmp') do |f|
    f.write match[1] + 'main(){}'
    f.close
    Tempfile.open(['a-', '.o'], 'tmp') do |o|
      o.close
      raw = `2>&1 gcc -c -g -w -O -m32 #{f.path.inspect} -o #{o.path.inspect} && objdump -S -M intel #{o.path.inspect}`.encode("UTF-8", "GBK", replace: '?', invalid: :replace, undef: :replace, fallback: '?').chomp("\n")
      m = raw.match /^Disassembly of section \.text:\s+(.+?)\n\S+?\s\<_main\>/m
      m ? m[1].gsub("\n\n", "\n").chomp : raw
    end
  end
end
