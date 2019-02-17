$procs = {}

def R(cond, &blk)
  $procs[cond] = blk
end

def D(&blk)
  blk.call
end

def T(input)
  $procs.each do |cond, blk|
    m = cond.match input
    puts blk.call(match: m, qq: 123456789) if m
  end
end

:eval
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

T <<-EOS
-disasm add(a,b){return a+b;}
EOS
