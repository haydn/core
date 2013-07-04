current_directory = Pathname(__FILE__).dirname.expand_path
require File.join(current_directory, "admin", "form_builder")

module Gluttonberg
    # Helpers specific to the administration interface. The majority are
    # related to forms, but there are other short cuts for things like navigation.
    module Admin
      include Messages
      include Form
      include Assets

      # Returns a link for sorting assets in the library
      def sorter_link(name, param, url)
        opts = {}
        route_opts = { :order => param , :order_type => "asc" }
        if param == params[:order] || (!params[:order] && param == 'date-added')
          opts[:class] = "current"
          unless params[:order_type].blank?
            route_opts[:order_type] = (params[:order_type] == "asc" ? "desc" : "asc" )
          else
            route_opts[:order_type] = "desc"
          end
          opts[:class] << (route_opts[:order_type] == "asc" ? " desc" : " asc" )
        end

        link_to(name, url + "?" + route_opts.to_param , opts)
      end

      # If it's passed a label this method will return a fieldset, otherwise it
      # will just return the contents wrapped in a block.
      def block(label = nil, opts = {}, &blk)
        if label
          field_set_tag(label) do
            content_tag(:fieldset, opts, &blk)
          end
        else
          content_tag(:fieldset, opts, &blk)
        end
      end

      # Writes out a nicely styled subnav with an entry for each of the
      # specified links.
      def sub_nav(&blk)
        content_tag(:ul, :id => "subnav", :class => "nav nav-pills", &blk)
      end

      # Writes out a link styled like a button. To be used in the sub nav only
      def nav_link(*args)
        class_names = "button"
        class_names = "#{class_names} #{args[2][:class]}" if args.length >= 3
        content_tag(:li, active_link_to(args[0] , args[1] , :title => args[0]), :class => class_names)
      end

      def website_title
        title = Gluttonberg::Setting.get_setting("title")
        (title.blank?)? "Gluttonberg" : title.html_safe
      end

      # Writes out a row for each page and then for each page's children,
      # iterating down through the heirarchy.
      def page_table_rows(pages, output = "", inset = 0 , row = 0)
        pages.each do |page|
          row += 1
          output << "<li class='dd-item' data-id='#{page.id}'>"
            output << render( :partial => "gluttonberg/admin/content/pages/row", :locals => { :page => page, :inset => inset , :row => row })
            if page.children.count > 0
              output << "<ol class='dd-list'>"
                page_table_rows(page.children.includes(:user, :localizations), output, inset + 1 , row)
              output << "</ol>"
            end
          output << "</li>"
        end
        output.html_safe
      end

      def custom_stylesheet_link_tag
        if Rails.configuration.custom_css_for_cms == true
          stylesheet_link_tag "gb_custom"
        end
      end

      def custom_javascript_include_tag
        if Rails.configuration.custom_js_for_cms == true
          javascript_include_tag "gb_custom"
        end
      end

      def tags_string(tag_type)
        @themes = ActsAsTaggableOn::Tag.find_by_sql(%{select DISTINCT tags.id , tags.name
          from tags inner join taggings on tags.id = taggings.tag_id
          where context = '#{tag_type}'
        })
        output = ""
        @themes.each do |theme|
          output << "," unless output.blank?
          output << theme.name
        end
        output
      end

      def date_format(date_time)
        if date_time < 1.week.ago
          date_time.strftime("%d/%m/%Y")
        else
          time_ago_in_words(date_time)
        end
      end

      def backend_logo(default_logo_image_path , html_opts={}, thumbnail_type = :backend_logo)
        backend_logo = Gluttonberg::Setting.get_setting("backend_logo")
        if !backend_logo.blank? && backend_logo.to_i > 0
          asset = Asset.where(:id => backend_logo).first
          unless asset.blank?
            path = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)
            content_tag(:img , "" , html_opts.merge( :alt => asset.name , :src => path ) )
          else
            image_tag(default_logo_image_path)
          end
        end
      end

      def sortable_column(column, title = nil)
        title ||= column.titleize
        css_class = column == sort_column ? "current #{sort_direction}" : nil
        direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
        new_params = params.merge(:sort => column, :direction => direction)
        link_to title, new_params, {:class => css_class}
      end

      def slug_donotmodify_val
        action_name == "edit"  || action_name == "update"
      end

      def current_domain
        domain = "#{request.protocol}#{request.host_with_port}/"
        domain.strip
      end

    end # Admin
end # Gluttonberg