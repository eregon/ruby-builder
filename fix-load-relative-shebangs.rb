require 'rbconfig'

bindir = RbConfig::CONFIG["bindir"]

FIRST_LINE = "#!/bin/sh\n"
RUBY_SHEBANG = %r{^#!/usr/bin/env ruby$}
RUBYGEMS_LINE = /This file was generated by RubyGems/

Dir.glob("#{bindir}/*") do |file|
  exe = "bin/#{File.basename(file)}"

  if File.binread(file, FIRST_LINE.bytesize) == FIRST_LINE
    puts "\nFound load-relative prolog in #{exe}"
    contents = File.binread(file)
    rubygems_line = contents.lines.index { |line| RUBYGEMS_LINE =~ line }

    if !rubygems_line
      puts "No RubyGems line in #{exe}, skipping it"
    elsif rubygems_line == 2
      # RubyGems expects RUBYGEMS_LINE to match the 3rd line
      # https://github.com/rubygems/rubygems/blob/6d7fe84753/lib/rubygems/installer.rb#L220
      # Otherwise, it will consider the executable to be conflict and ask whether to override,
      # and that results in an error when STDIN is not interactive
    else
      puts "The RubyGems line in #{exe} is not the 3rd line (but line #{rubygems_line+1}), fixing it"

      index = contents =~ RUBY_SHEBANG
      raise "Could not find ruby shebang in:\n#{contents}" unless index
      contents = contents[index..-1]

      rubygems_line = contents.lines.index { |line| RUBYGEMS_LINE =~ line }
      unless rubygems_line == 2
        raise "The RubyGems line is still not 3rd in #{exe}:\n#{contents}"
      end

      File.binwrite(file, contents)
    end
  end
end