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
# /deqrcode [pic]
require 'mechanize'
require 'nokogiri'
R /\/deqrcode\s+\[CQ:image,file=(.+?)\]/ do |match:, **|
  begin
    D { Nokogiri::HTML(Mechanize.new.get('https://zxing.org/w/decode.jspx').form_with(method: 'GET'){ |c| c.fields.first.value = File.read("data/image/#{match[1]}.cqimg")[/^url=(.*)$/, 1] }.submit.body).css('#result pre').first.text }
  rescue
    $@.unshift($!).join $/
  end
end

# T <<-EOS
# -disasm
# void f(){ putchar(42); }
# EOS
