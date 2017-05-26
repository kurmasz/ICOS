#################################################################
#
# generate_large_code.rb
#
# Generates a C file with a large code base (i.e., a lot of functions)
# Used to test ICOS's boot loader.
#
#################################################################


def make_fn(num) 
  body=<<-HERE
    unsigned func#{num}(unsigned x) {
      return x + #{num};
    }
  HERE
end

#
# Main
#

if (ARGV.length < 1) 
  $stderr.puts "Usage generate_large_code.rb num_functions"
  exit
end

num_functions = ARGV[0].to_i

if (num_functions < 1)
  $stderr.puts "Parameter must be an integer."
  $stderr.puts "Usage generate_large_code.rb num_functions"
  exit
end


calls = []

(1..num_functions).each do |i|
    puts make_fn(i);
    calls << "    sum = func#{i}(sum);"
end


  body=<<-HERE
     unsigned use_all(unsigned x) {
       unsigned sum = x;
       #{calls.join("\n")}
       return sum;
     }

     unsigned expected_output(unsigned x) {
         unsigned nf =  #{num_functions};
         return (nf*(nf+1) / 2) + x;
     }
  HERE

  puts body
