# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class ArticlesController < Gluttonberg::Admin::BaseController
        before_filter :is_blog_enabled
        before_filter :find_blog , :except => [:create]
        before_filter :find_article, :only => [:show, :edit, :update, :delete, :destroy , :duplicate]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        record_history :@article , :title

        def index
          conditions = {:blog_id => @blog.id}
          conditions[:user_id] = current_user.id unless current_user.super_admin?
          @articles = Article.where( conditions).order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page])
        end


        def show
          @comment = Comment.new
        end

        def new
          @article = Article.new
          @article_localization = ArticleLocalization.new(:article => @article , :locale_id => Locale.first_default.id)
          @authors = User.all
        end

        def create
          params[:gluttonberg_article_localization][:article][:name] = params[:gluttonberg_article_localization][:title]
          article_attributes = params["gluttonberg_article_localization"].delete(:article)
          @article = Article.new(article_attributes)
          if @article.save
            @article.create_localizations(params["gluttonberg_article_localization"])
            flash[:notice] = "The article was successfully created."
            redirect_to edit_admin_blog_article_path(@article.blog, @article)
          else
            render :edit
          end
        end

        def edit
          @authors = User.all
          unless params[:version].blank?
            @version = params[:version]
            @article.revert_to(@version)
          end
        end

        def update
          article_attributes = params["gluttonberg_article_localization"].delete(:article)
          if @article_localization.update_attributes(params[:gluttonberg_article_localization])
            article = @article_localization.article
            article.current_slug = article.slug
            article.assign_attributes(article_attributes)
            article.previous_slug = article.current_slug if article.slug_changed?
            article.save

            _log_article_changes

            flash[:notice] = "The article was successfully updated."
            redirect_to edit_admin_blog_article_path(@article.blog, @article)
          else
            flash[:error] = "Sorry, The article could not be updated."
            render :edit
          end
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete Article '#{@article.title}'?",
            :url        => admin_blog_article_path(@blog, @article),
            :return_url => admin_blog_articles_path(@blog),
            :warning    => ""
          )
        end

        def destroy
          title = @article.current_localization.title
          if @article.destroy
            flash[:notice] = "The article was successfully deleted."
            redirect_to admin_blog_articles_path(@blog)
          else
            flash[:error] = "There was an error deleting the Article."
            redirect_to admin_blog_articles_path(@blog)
          end
        end

        def duplicate
          @duplicated_article = @article.duplicate
          @duplicated_article.user_id = current_user.id
          if @duplicated_article
            flash[:notice] = "The article was successfully duplicated."
            redirect_to edit_admin_blog_article_path(@blog, @duplicated_article)
          else
            flash[:error] = "There was an error duplicating the article."
            redirect_to admin_blog_articles_path(@blog)
          end
        end

        protected

          def find_blog
            @blog = Blog.where(:id => params[:blog_id]).first
          end

          def find_article
            if params[:localization_id].blank?
              conditions = { :article_id => params[:id] , :locale_id => Locale.first_default.id}
              @article_localization = ArticleLocalization.where(conditions).first
            else
              @article_localization = ArticleLocalization.where(:id => params[:localization_id]).first
            end
            @article = Article.where(:id => params[:id]).first
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Article
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Article
          end

          def _log_article_changes
            localization_detail = ""
            if Gluttonberg.localized?
              localization_detail = " (#{@article_localization.locale.slug}) "
            end
            if Gluttonberg.localized?
              Gluttonberg::Feed.log(current_user,@article_localization,"#{@article_localization.title}#{localization_detail}" , "updated")
            end
          end

      end
    end
  end
end
