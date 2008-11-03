# -*- ruby -*-
#--
# Copyright (C) 2008 David Kellum
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++

require 'rubygems'

ENV['NODOT'] = "no thank you"
require 'hoe'

$LOAD_PATH << './lib'
require 'jetty-jsp/base'

ASSEMBLY = "target/jetty-jsp-assembly-1.0-bin.dir"

desc "Update the Manifest with actual jars"
task :manifest => [ ASSEMBLY ] do
  out = File.new( 'Manifest.txt', 'w' ) 
  begin
    out.write <<END
History.txt
Manifest.txt
README.txt
Rakefile
pom.xml
assembly.xml
lib/jetty-jsp.rb
lib/jetty-jsp/base.rb
END
    out.puts( Dir.glob( File.join( ASSEMBLY, '*.jar' ) ).map do |jar|
                File.join( 'lib', 'jetty-jsp', File.basename( jar ) )
              end )
  ensure
    out.close
  end
end


file ASSEMBLY => [ 'pom.xml', 'assembly.xml' ] do
  sh( 'mvn package' )
end

JAR_FILES = File.new( 'Manifest.txt' ).readlines.map { |f| f.strip }\
.select { |f| f =~ /\.jar$/ }

JARS = JAR_FILES.map { |f| File.basename( f.strip ) }

JARS.each do |jar|
  file "lib/jetty-jsp/#{jar}" => [ ASSEMBLY ] do
    cp_r( File.join( ASSEMBLY, jar ), 'lib/jetty-jsp' )
  end
end

[ :gem, :test ].each { |t| task t => JAR_FILES }

task :mvn_clean do
  rm_f( JAR_FILES )
  sh( 'mvn clean' )
end
task :clean => :mvn_clean 

hoe = Hoe.new( "jetty-jsp", JettyJspBase::VERSION ) do |p|
  p.developer( "David Kellum", "dek-ruby@gravitext.com" )
  p.extra_deps << [ 'jetty', "~> #{JettyJspBase::JETTY_VERSION}" ]
  p.rubyforge_name = "rjack"
  p.rdoc_pattern = /^(lib.*\.(rb|txt))|[^\/]*\.txt$/
end
