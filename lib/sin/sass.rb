module Sin

  # Generate valid CSS using Sass (part of Haml)
  #
  # Sass templates can be in external files with <tt>.sass</tt> extension
  # or can use Sin's in_file_templates.  In either case, the file can
  # be rendered by passing the name of the template to the +sass+ method
  # as a symbol.
  #
  # Unlike Haml, Sass does not support a layout file, so the +sass+ method
  # will ignore both the default <tt>layout.sass</tt> file and any parameters
  # passed in as <tt>:layout</tt> in the options hash.
  #
  # === Sass Template Files
  #
  # Sass templates can be stored in separate files with a <tt>.sass</tt>
  # extension under the view path.
  #
  # Example:
  #   get '/stylesheet.css' do
  #     header 'Content-Type' => 'text/css; charset=utf-8'
  #     sass :stylesheet
  #   end
  #
  # The "views/stylesheet.sass" file might contain the following:
  #
  #  body
  #    #admin
  #      :background-color #CCC
  #    #main
  #      :background-color #000
  #  #form
  #    :border-color #AAA
  #    :border-width 10px
  #
  # And yields the following output:
  #
  #   body #admin {
  #     background-color: #CCC; }
  #   body #main {
  #     background-color: #000; }
  #
  #   #form {
  #     border-color: #AAA;
  #     border-width: 10px; }
  #
  #
  # NOTE: Haml must be installed or a LoadError will be raised the first time an
  # attempt is made to render a Sass template.
  #
  # See http://haml.hamptoncatlin.com/docs/rdoc/classes/Sass.html for comprehensive documentation on Sass.
  module Sass

    def sass(content, options = {})
      require 'sass'

      # Sass doesn't support a layout, so we override any possible layout here
      options[:layout] = false

      render(:sass, content, options)
    end

    private

    def render_sass(content, options = {})
      ::Sass::Engine.new(content).render
    end

  end
end