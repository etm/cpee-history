#!/usr/bin/ruby
#
# This file is part of CPEE-HISTORY.
#
# CPEE-HISTORY is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# CPEE-HISTORY is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with CPEE-HISTORY (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'riddl/server'
require 'json'
require 'date'
require 'fileutils'
require 'shellwords'
require 'xml/smart'
require 'systemu'

module CPEE
  module History
    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    module Util #{{{
      def git_commit(history,new,author)
        rp = File.realpath(history)
        crb = File.join(__dir__,'commands','commit.rb')
        system 'ruby ' + crb + ' ' + [rp, new, author].shelljoin + ' &'
      end

      def get_commits(history,path)
        rp = File.realpath(history)
        crb = File.join(__dir__,'commands','log.rb')
        res = systemu('ruby ' + crb + ' ' + [rp, path].shelljoin())
        commits = []
        dates = []
        res[1].split("\n").each() { |line|
          match_commit = line.match(/commit (.*)/)
          if(match_commit.nil?().!()) then
            commits.push({:uuid => match_commit[1]})
          end
          match_date = line.match(/Date:   (.*)/)
          if(match_date.nil?().!()) then
            commits.last()[:time] = DateTime.parse(match_date[1])
          end
        }
        return commits
      end

      def get_file_in_commit(history,path,commit)
        rp = File.realpath(history)
        crb = File.join(__dir__,'commands','show.rb')
        res = systemu('ruby ' + crb + ' ' + [rp, path,commit].shelljoin())
        return res[1]
      end


      def hash_to_xml(hash,root_name)
        doc = XML::Smart.string("<#{root_name}></#{root_name}>")
        hash.each() { |k,v|
          doc.root().append(XML::Smart.string("<#{k}>#{v}</#{k}>").root())
        }
        return doc
      end
    end #}}}

    class SaveFromCpeeStream < Riddl::Implementation #{{{
      include Util
      def response
        type = @p[0].value()
        topic = @p[1].value()
        event = @p[2].value()
        content = JSON.parse(@p[3].value().read())
        uuid = content['instance-uuid']
        if(Dir.exist?(File.join(@a[0][:history_dir],uuid)).!()) then
          FileUtils.mkdir(File.join(@a[0][:history_dir],uuid))
        end
        pp uuid
        pp type
        pp topic
        pp event
        pp content

        to_write = nil
        filename = nil
        if(type == 'event' && topic == 'description' && (event == 'change')) then
          to_write = XML::Smart.string(content['content']['description'])
          filename = File.join(@a[0][:history_dir],uuid,'description')
        elsif(type == 'event' && topic == 'dataelements' && event == 'modify') then
          to_write = hash_to_xml(content['content']['values'],'dataelements')
          filename = File.join(@a[0][:history_dir],uuid,'dataelements')
        elsif(type == 'event' && topic == 'endpoints' && event == 'modify') then
          to_write = hash_to_xml(content['content']['values'],'endpoints')
          filename = File.join(@a[0][:history_dir],uuid,'endpoints')
        elsif(type == 'event' && topic == 'attributes' && event == 'modify') then
          to_write = hash_to_xml(content['content']['values'],'attributes')
          filename = File.join(@a[0][:history_dir],uuid,'attributes')
        end
        if(to_write.nil?().!() && filename.nil?().!()) then
          File.write(filename,to_write)
          history = filename.split('/')[0..-3].join('/')
          new = filename.split('/')[-2..-1].join('/')
          author = 'E. L. Brown'
          git_commit(history,new,author)
          return Riddl::Parameter::Complex.new("json","application/json",{:updated_file => filename}.to_json())
        else
          return Riddl::Parameter::Complex.new("json","application/json",{:error => 'no file or to_write'}.to_json())
        end
      end
    end #}}}

    class GetInstances < Riddl::Implementation #{{{
      include Util
      def response
        return Riddl::Parameter::Complex.new("json","application/json",{:instances => Dir.children(@a[0][:history_dir]).filter() { |el| el.start_with?('.').!() }.sort() { |a,b| a <=> b }}.to_json())
      end
    end #}}}

    class GetCommits < Riddl::Implementation #{{{
      include Util
      def response
        history = @a[0][:history_dir]
        commits = get_commits(history,@r[-2])
        return Riddl::Parameter::Complex.new("json","application/json",{:commits => commits}.to_json())
      end
    end #}}}

    class GetFile < Riddl::Implementation #{{{
      include Util
      def response
        history = @a[0][:history_dir]
        file = @r[-1]
        commit = @r[-2]
        instance = @r[-4]
        file_content = get_file_in_commit(history,File.join(instance,file),commit)
        ret = file_content != "\n" ? XML::Smart.string(file_content) : XML::Smart.string("<#{file}></#{file}>")
        return Riddl::Parameter::Complex.new("xml","application/xml",ret.to_s())
      end
    end #}}}

    class GetTestsetFile < Riddl::Implementation #{{{
      include Util
      def response
        history = @a[0][:history_dir]
        commit = @r[-2]
        instance = @r[-4]
        description = get_file_in_commit(history,File.join(instance,'description'),commit)
        dataelements = get_file_in_commit(history,File.join(instance,'dataelements'),commit)
        endpoints = get_file_in_commit(history,File.join(instance,'endpoints'),commit)
        attributes = get_file_in_commit(history,File.join(instance,'attributes'),commit)
        description_xml = description != "\n" ? XML::Smart.string(description) : XML::Smart.string('<description xmlns="http://cpee.org/ns/description/1.0"></description>')
        dataelements_xml = dataelements != "\n" ? XML::Smart.string(dataelements) : XML::Smart.string('<dataelements></dataelements>')
        endpoints_xml = endpoints != "\n" ? XML::Smart.string(endpoints) : XML::Smart.string('<endpoints></endpoints>')
        attributes_xml = attributes != "\n" ? XML::Smart.string(attributes) : XML::Smart.string('<attributes></attributes>')
        testset = XML::Smart.string(File.read(File.join(__dir__,'testset_skeleton.xml')))
        testset.register_namespace(:properties,'http://cpee.org/ns/properties/2.0')
        testset.register_namespace(:description,'http://cpee.org/ns/description/1.0')
        testset.find('properties:testset/properties:dataelements').first().replace_by(dataelements_xml.root())
        testset.find('properties:testset/properties:endpoints').first().replace_by(endpoints_xml.root())
        testset.find('properties:testset/properties:attributes').first().replace_by(attributes_xml.root())
        testset.find('properties:testset/properties:description/description:description').first().replace_by(description_xml.root())
        return Riddl::Parameter::Complex.new("xml","application/xml",testset.to_s())
      end
    end #}}}


    def self::implementation(opts)
      opts[:base]        ||= Dir.pwd
      opts[:history_dir]   = File.expand_path(opts[:history_dir] || 'history', opts[:base])
      FileUtils.mkdir_p opts[:history_dir]

      Proc.new do
        on resource do
          run SaveFromCpeeStream, opts if post
          on resource 'instances' do
            run GetInstances, opts if get
            on resource '[a-zA-Z\d_-]+' do
              on resource 'commits' do
                run GetCommits, opts if get
                on resource '[a-zA-Z\d_-]+' do
                  on resource 'description' do
                    run GetFile, opts if get
                  end
                  on resource 'dataelements' do
                    run GetFile, opts if get
                  end
                  on resource 'endpoints' do
                    run GetFile, opts if get
                  end
                  on resource 'attributes' do
                    run GetFile, opts if get
                  end
                  on resource 'testset' do
                    run GetTestsetFile, opts if get
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
