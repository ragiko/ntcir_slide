require "pp"

path = "./query_likelihood/result_all/01.txt"
h = Hash.new() { |h,k| h[k] = [] }

File.open(path).each_line do |l|
  a = l.split(" ")

  if /(\d{2}\-\d{2})_\d{3}/ =~ a[0]
    h[$1] << a
  end
end


max = -1
min = 100000000
b = []

h.sort.each do |k, v|
  puts "#{k} size: #{v.size}"
  b << v.size

  if max < v.size
    max = v.size
  end

  if min > v.size
    min = v.size
  end
end

puts "max"
puts max

puts "min"
puts min

puts "ave"
puts b.inject(0) { |memo, x| memo += x } / b.size
