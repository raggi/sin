module Sin
  # Generating conservative XML content using Builder templates.
  #
  # Builder templates can be inline by passing a block to the builder method,
  # or in external files with +.builder+ extension by passing the name of the
  # template to the +builder+ method as a Symbol.
  #
  # === Inline Rendering
  #
  # If the builder method is given a block, the block is called directly with
  # an +XmlMarkup+ instance and the result is returned as String:
  #   get '/who.xml' do
  #     builder do |xml|
  #       xml.instruct!
  #       xml.person do
  #         xml.name "Francis Albert Sin",
  #           :aka => "Frank Sin"
  #         xml.email 'frank@capitolrecords.com'
  #       end
  #     end
  #   end
  #
  # Yields the following XML:
  #   <?xml version='1.0' encoding='UTF-8'?>
  #   <person>
  #     <name aka='Frank Sin'>Francis Albert Sin</name>
  #     <email>Frank Sin</email>
  #   </person>
  #
  # === Builder Template Files
  #
  # Builder templates can be stored in separate files with a +.builder+
  # extension under the view path. An +XmlMarkup+ object named +xml+ is
  # automatically made available to template.
  #
  # Example:
  #   get '/bio.xml' do
  #     builder :bio
  #   end
  #
  # The "views/bio.builder" file might contain the following:
  #   xml.instruct! :xml, :version => '1.1'
  #   xml.person do
  #     xml.name "Francis Albert Sin"
  #     xml.aka "Frank Sin"
  #     xml.aka "Ol' Blue Eyes"
  #     xml.aka "The Chairman of the Board"
  #     xml.born 'date' => '1915-12-12' do
  #       xml.text! "Hoboken, New Jersey, U.S.A."
  #     end
  #     xml.died 'age' => 82
  #   end
  #
  # And yields the following output:
  #   <?xml version='1.1' encoding='UTF-8'?>
  #   <person>
  #     <name>Francis Albert Sin</name>
  #     <aka>Frank Sin</aka>
  #     <aka>Ol&apos; Blue Eyes</aka>
  #     <aka>The Chairman of the Board</aka>
  #     <born date='1915-12-12'>Hoboken, New Jersey, U.S.A.</born>
  #     <died age='82' />
  #   </person>
  #
  # NOTE: Builder must be installed or a LoadError will be raised the first
  # time an attempt is made to render a builder template.
  #
  # See http://builder.rubyforge.org/ for comprehensive documentation on
  # Builder.
  module Builder

    def builder(content=nil, options={}, &block)
      options, content = content, nil if content.is_a?(Hash)
      content = Proc.new { block } if content.nil?
      render(:builder, content, options)
    end

    private

    def render_builder(content, options = {}, &b)
      require 'builder'
      xml = ::Builder::XmlMarkup.new(:indent => 2)
      case content
      when String
        eval(content, binding, '<BUILDER>', 1)
      when Proc
        content.call(xml)
      end
      xml.target!
    end

  end
end