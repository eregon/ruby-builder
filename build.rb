raise unless ARGV.size == 2
engine, version = ARGV
engine_version = "#{engine}-#{version}"
engine_versions = engine == 'truffleruby' ? "#{engine_version}, truffleruby+graalvm-#{version}" : engine_version

def sh(*command)
  puts command.join(' ')
  raise "#{command} failed" unless system(*command)
end

file = ".github/workflows/build.yml"
lines = File.readlines(file)

ruby_lines = lines.select { |line| line.include?('ruby: ') }
raise unless ruby_lines.size == 2

unix, windows = ruby_lines
unix.sub!(/ruby: .+/, "ruby: [#{engine_versions}]")
if engine == 'jruby'
  windows.sub!(/jruby-version: .+/, "jruby-version: #{version}, ruby: #{engine_version} }")
end

if_lines = lines.select { |line| line.match?(/^    if: (true|false)/) }
raise unless if_lines.size == 2
if_lines[0].sub!(/if: (true|false)/, 'if: true')
if_lines[1].sub!(/if: (true|false)/, "if: #{engine == 'jruby'}")

File.write(file, lines.join)

sh 'git', 'add', file
sh 'git', 'commit', '-m', "Build #{engine_version}"
