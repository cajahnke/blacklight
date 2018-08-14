module ApplicationHelper
  def render_thumbnail(document, options)
    if document[:attr_img].present?
      @im = document['attr_img']
      @tit = document['dc_title'].to_s
      @streamArr = document['stream_name'][0].split('/')
      @streamlen = (@streamArr.last.include? ".html") ? 4 : 3
      @stream = @streamArr.length > 4 ? @streamArr.slice(3,@streamArr.length - @streamlen) : []
      @thumb = @im.index('Instagram').nil? && @im.length > 0 ? @im.select {|i| i =~ /(\.?\.?\/\S+(?:.jpeg)|(?:.jpg)|(?:.png))/}[0] : @im.slice(@im.index('Instagram') + 1,@im.length - (@im.index('Instagram') + 1)).select {|i| i =~ /(\.?\.?\/\S+(?:.jpeg)|(?:.jpg)|(?:.png))/}[@im.slice(@im.index('Instagram') + 1,@im.length - (@im.index('Instagram') + 1)).select {|i| i =~ /(\.?\.?\/\S+(?:.jpeg)|(?:.jpg)|(?:.png))/}.length - 1]
      if !@thumb.nil? && @thumb[0] == '/'
        image_tag(
          "http://www.hrc.utexas.edu" + @thumb,
          options.merge(alt: @tit, style: 'max-width: 350px; max-height: 175px;')
        )
      elsif !@thumb.nil? && @thumb[0,2] == '..'
        image_tag(
          "http://www.hrc.utexas.edu/" + @stream.slice(0,@stream.length - 1).join('/') + @thumb[2,@thumb.length - 2],
          options.merge(alt: @tit, style: 'max-width: 350px; max-height: 175px;')
        )
      elsif !@thumb.nil?
        image_tag(
          "http://www.hrc.utexas.edu/" + @stream.join('/') + '/' + @thumb,
          options.merge(alt: @tit, style: 'max-width: 350px; max-height: 175px;')
        )
      end
    elsif document[:images_t ].present?
        image_tag(
          "http://hrch-research.austin.utexas.edu" + document[:images_t ].split(',').shift,
          options.merge(alt: document['OperaTitle_t'].to_s, style: 'max-width: 350px; max-height: 175px;')
        )
    else
      return
    end
  end
end
