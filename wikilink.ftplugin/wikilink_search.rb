#!/usr/bin/ruby -w

require 'uri'

if RUBY_VERSION.to_f > 1.9
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

# search folder strings may start with ~ and final slash is optional
search_folders = [
  '~/Dropbox/Notes/',
  '~/Dropbox/Notes Archive/',
  '~/Desktop/'
]
extensions = 'md,ft,txt,png,jpg,jpeg,pdf'        # comma-separated list
recursive = true                                 # also search subfolders?

def openFile file
  target_file = file.gsub(/"/){ %q[\"] }
  
  # open the file in the default app for its type
  %x[open "#{target_file}"]
  
  # this next version will always open in FoldingText, but it sometimes fails due
  # to permissions. May be a sandboxing issue
  # %x[osascript -e 'tell application "FoldingText" to open "#{target_file}"']
end

def openInNV search_term
  %x[open "nv://find/#{search_term}"]
end

search_term_i = 0
doc_path_i = 1

if ARGV.length < 1 # must be at least 1 argument
  exit
end

search_term_uri = ARGV[search_term_i]
search_term = URI.decode_www_form_component(search_term_uri)
doc_path = ''
if ARGV.length > doc_path_i
  doc_path = ARGV[doc_path_i]
end

file_glob = search_term.gsub(/[^\w\-]+/, '*') + "*.{#{extensions}}"
file_glob = '*' + file_glob            # allow search to start in middle of filename
file_glob.gsub!(/\*+/, '*')            # clean up successive *'s
if recursive
  file_glob = '**/' + file_glob
end

if doc_path.length > 0
  doc_folder = doc_path.slice(/^.+\//)
  search_folders.unshift doc_folder
end

target_file = nil
search_folders.each do |folder|
  folder.strip!
  folder.gsub!(/^~/, Dir.home)
  folder << '/' if not folder.match(/\/$/)
  
  files = Dir.glob(folder + file_glob, File::FNM_CASEFOLD)
  
  if files.length > 0
    target_file = files[0]
    break
  end
end
  
if not target_file.nil?
  openFile target_file
else
  # if file was not found, search for it in Notational Velocity (or nvALT)
  openInNV search_term_uri
end
