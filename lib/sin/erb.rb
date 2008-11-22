module Sin
  module Erb

    def erb(content, options={})
      require 'erb'
      render(:erb, content, options)
    end

    private

    def render_erb(content, options = {})
      locals_opt = options.delete(:locals) || {}

      locals_code = ""
      locals_hash = {}
      locals_opt.each do |key, value|
        locals_code << "#{key} = locals_hash[:#{key}]\n"
        locals_hash[:"#{key}"] = value
      end

      body = ERB.new(content).src
      eval("#{locals_code}#{body}", binding)
    end

  end
end