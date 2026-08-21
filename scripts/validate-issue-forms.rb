#!/usr/bin/env ruby

require "yaml"

forms = Dir[File.join(__dir__, "..", ".github", "ISSUE_TEMPLATE", "*.yml")]
errors = []
names = []
allowed_types = %w[checkboxes dropdown input markdown textarea upload].freeze

forms.each do |path|
  document = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
  filename = File.basename(path)

  unless document.is_a?(Hash)
    errors << "#{filename}: document must be a mapping"
    next
  end

  if filename == "config.yml"
    errors << "#{filename}: blank_issues_enabled must be boolean" unless [true, false].include?(document["blank_issues_enabled"])
    next
  end

  %w[name description body].each do |key|
    errors << "#{filename}: missing #{key}" unless document.key?(key)
  end

  names << document["name"]
  body = document["body"]
  unless body.is_a?(Array) && !body.empty?
    errors << "#{filename}: body must be a non-empty array"
    next
  end

  ids = []
  body.each_with_index do |element, index|
    unless element.is_a?(Hash)
      errors << "#{filename}: body item #{index + 1} must be a mapping"
      next
    end

    type = element["type"]
    errors << "#{filename}: body item #{index + 1} has invalid type" unless allowed_types.include?(type)
    next if type == "markdown"

    id = element["id"]
    errors << "#{filename}: body item #{index + 1} needs a valid id" unless id&.match?(/\A[a-zA-Z0-9_-]+\z/)
    ids << id if id
  end

  errors << "#{filename}: field ids must be unique" unless ids.uniq.length == ids.length
end

errors << "issue form names must be unique" unless names.compact.uniq.length == names.compact.length

abort(errors.join("\n")) unless errors.empty?
puts "issue forms valid"

