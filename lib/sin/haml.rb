module Sin
  module Haml

    def haml(content, options={})
      require 'haml'
      render(:haml, content, options)
    end

    private

    def render_haml(content, options = {}, &b)
      haml_options = (options[:options] || {}).
        merge(@app.options[:haml] || {})
      ::Haml::Engine.new(content, haml_options).
      render(options[:scope] || self, options[:locals] || {}, &b)
    end

  end
end