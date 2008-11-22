module Sin
  module RenderingHelpers

    def render(renderer, template, options={})
      m = method("render_#{renderer}")
      result = m.call(resolve_template(renderer, template, options), options)
      if layout = determine_layout(renderer, template, options)
        result = m.call(resolve_template(renderer, layout, options), options) { result }
      end
      result
    end

    def determine_layout(renderer, template, options)
      return if options[:layout] == false
      layout_from_options = options[:layout] || :layout
      resolve_template(renderer, layout_from_options, options, false)
    end

  private

    def resolve_template(renderer, template, options, scream = true)
      case template
      when String
        template
      when Proc
        template.call
      when Symbol
        if proc = templates[template]
          resolve_template(renderer, proc, options, scream)
        else
          read_template_file(renderer, template, options, scream)
        end
      else
        nil
      end
    end

    def read_template_file(renderer, template, options, scream = true)
      path = File.join(
        options[:views_directory] || @app.options[:views],
        "#{template}.#{renderer}"
      )
      unless File.exists?(path)
        raise Errno::ENOENT.new(path) if scream
        nil
      else
        File.read(path)
      end
    end

    def templates
      @app.templates
    end

  end
end