require 'redcarpet'

module Documentation
  class MarkdownRenderer < Redcarpet::Render::HTML

    attr_accessor :page

    include ActionView::Helpers::TagHelper

    def block_code(code, language)
      title = nil
      code.gsub!(/\A\:\:(.*)$/) { title = $1 ; nil }
      String.new.tap do |s|
        s << "<p class='codeTitle'>#{title}</p>" if title
        begin
          require 'pygments'
          s << Pygments.highlight(code, :lexer => language)
        rescue LoadError
          require 'rouge'    
          lexer = Lexer.find_fancy(language, code) || Lexers::PlainText

          # XXX HACK: Redcarpet strips hard tabs out of code blocks,
          # so we assume you're not using leading spaces that aren't tabs,
          # and just replace them here.
          if lexer.tag == 'make'
            code.gsub! /^    /, "\t"
          end

          formatter = Formatters::HTML.new(:css_class => "highlight #{lexer.tag}")
          s << formatter.format(lexer.lex(code))
        end
      end
    rescue
      "<div class='highlight'><pre>#{code}</pre></div>"
    end

    def link(link, title, content)
      if link =~ /\A\^/
        case link
        when /\A\^\.\/(.*)/
          # ^./pagename
          # Links to pages on the same level as the current page
          link = "{{docRoot}}/#{page.parents.map(&:permalink).join('/')}/#{$1}"
        when /\A\^\/(.*)/
          # ^/full/path
          # Links to a page frmo the root of the docs
          link = "{{docRoot}}/#{$1}"
        when /\A\^(.*)/
          # ^child/item
          # Links to a child of the current page
          link = "{{docRoot}}/#{page.full_permalink}/#{$1}"
        end
      end
      "<a href='#{link}' title='#{title}'>#{content}</a>"
    end

    def image(src, title, alt)
      if alt.gsub!(/\*([\w\-\s]+)\z/, '')
        klass = "imgcontainer #{$1}"
      else
        klass = nil
      end
      content_tag :span, tag(:img, :src => src, :title => title, :alt => alt), :class => klass
    end

    def paragraph(text)
      klass = ''
      text.gsub!(/\A(\w+)\:/) do
        klass = $1
        nil
      end
      text.sub!(/ ([^ ]+)$/, '&nbsp;\1')
      "<p class='#{klass.downcase}'>#{text}</p>"
    end

  end
end
