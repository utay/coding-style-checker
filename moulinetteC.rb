#!/usr/bin/env ruby
# encoding: utf-8

class MoulinetteC
  def initialize(files={})
    @files = files
    @filename = nil
    @currentLineNo = nil
    @functions = []
  end

  def isValidExtension(filename)
    File.extname(filename) == ".c" || File.extname(filename) == ".h"
  end

  def check80Columns(lineContent)
    i = 0;
    for n in 0..lineContent.length - 1
      if lineContent[n] == "\t" && lineContent[n - 1] == "\t"
        i += 8
      elsif lineContent[n] == "\t"
        i += 8 - n % 8
      else
        i += 1
      end
    end
    if i >= 80
      errorNorme "more than 80 characters"
    end
  end

  def checkSemiColon(lineContent)
    quote = false
    for n in 0..lineContent.length - 1
      quote = !quote if lineContent[n].chr == "'" || lineContent[n].chr == '"'
      if (((lineContent[n].chr == ";" && !quote) && lineContent[n - 1].chr == " ") &&
          lineContent[n + 1].chr == "\n")
        errorNorme "invalid semicolon position"
      end
    end
  end

  def checkTrailingSpaces(lineContent)
    if (lineContent =~ /[ \t]$/)
      errorNorme "space at the EOL"
    end
  end

  def checkWrongPositionSpaces(lineContent)
    if (lineContent =~ /[ \t](if|else|return|while|for)(\()/)
      errorNorme "no space after a keyword"
    end
  end

  def checkWrongPositionComa(lineContent)
    quote = false
    for n in 0..lineContent.length - 1
      quote = !quote if lineContent[n].chr == "'" || lineContent[n].chr == '"'
      if (((lineContent[n].chr == ";" || lineContent[n].chr == ",") && !quote) &&
          lineContent[n + 1].chr != " " && lineContent[n + 1].chr != "\n")
        errorNorme "invalid comma position"
      end
    end
  end

  def checkNbMaxArguments(lineContent)
    if (lineContent =~ /\((.*),(.*),(.*),(.*),(.*)\)/)
      errorNorme "more than 4 arguments in parameters functions"
    end
  end

  def checkInLine(lineContent)
    check80Columns lineContent
    checkSemiColon lineContent
    checkTrailingSpaces lineContent
    checkWrongPositionSpaces lineContent
    checkWrongPositionComa lineContent
    checkNbMaxArguments lineContent
  end

  def checkInFile
    tooManyLines = 0
    bool = false
    @functions.length.times do |i|
      tooManyLines = @functions[i]["end"] - @functions[i]["begin"]
      if tooManyLines > 27
        errorNorme("More than 25 lines", @functions[i]["begin"] + tooManyLines)
        tooManyLines -= 1
      end
      if i > 4 && !bool
        errorNorme("More than 5 functions per file", @functions[i]["begin"])
        bool = true
      end
    end
    @functions = []
  end

  def parseFile(filename)
    @currentLineNo = 1
    @filename = filename
    scope = 0
    beginFunction = nil
    endFunction = nil
    begin
      File.readlines(filename).each do |lineContent|
        checkInLine lineContent
        if lineContent =~ /\s*{\s*/
          scope += 1
          beginFunction = @currentLineNo - 1 if scope == 1
        elsif lineContent =~ /\s*}\s*/
          scope -= 1
          if scope == 0
            endFunction = @currentLineNo
            @functions.push({"begin" => beginFunction,
                             "end" => endFunction})
          end
        end
        @currentLineNo += 1
      end
      checkInFile
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end
  end

  def checkNorme
    @files.each do |filename|
      puts "checking #{filename}..."
      if !isValidExtension filename
        puts "invalid extension of #{filename}: try #{File.basename(filename, File.extname(filename))}.c"
      end
      parseFile filename
    end
  end

  def errorNorme(type, line=@currentLineNo)
    STDERR.puts " #{@filename}:#{line}: #{type}"
  end
end

MoulinetteC.new(ARGV).checkNorme
