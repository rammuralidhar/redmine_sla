# frozen_string_literal: true

# Redmine SLA - Redmine's Plugin 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class SlasController < ApplicationController

  unloadable

  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla, only: [:show, :edit, :update]
  before_action :find_slas, only: [:context_menu, :destroy]

  helper :slas
  helper :context_menus
  helper :queries
  include QueriesHelper

  def index
    Rails.logger.warn "======>>> sla->index() <<<====== "
    retrieve_query(Queries::SlaQuery) 
    @entity_count = @query.slas.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.slas(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
  end

  def new
    @sla = Sla.new
    @sla.safe_attributes = params[:sla]
  end

  def create
    @sla = Sla.new
    @sla.safe_attributes = params[:sla]
    if @sla.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back_or_default slas_path
    else
      render :action => 'new'
    end
  end

  def update
    @sla.safe_attributes = params[:sla]
    if @sla.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default slas_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    @slas.each(&:destroy)
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default slas_path
  end

  def context_menu
    Rails.logger.warn "======>>> sla->context_menu() <<<====== "
    if @slas.size == 1
      @sla = @slas.first
    end
    can_edit = @slas.detect{|c| !c.editable?}.nil?
    can_delete = @slas.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_ids, @safe_attributes, @selected = [], [], {}
    @slas.each do |e|
      @sla_ids << e.id
      @safe_attributes.concat e.safe_attribute_names
      attributes = e.safe_attribute_names - (%w(custom_field_values custom_fields))
      attributes.each do |c|
        column_name = c.to_sym
        if @selected.key? column_name
          @selected[column_name] = nil if @selected[column_name] != e.send(column_name)
        else
          @selected[column_name] = e.send(column_name)
        end
      end
    end
    @safe_attributes.uniq!
    render layout: false
  end
 
  private

  def find_sla
    @sla = Sla.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_slas
    @slas = Sla.visible.where(id: (params[:id] || params[:ids])).to_a
    @sla = @slas.first if @slas.count == 1
    raise ActiveRecord::RecordNotFound if @slas.empty?
    #raise Unauthorized unless @slas.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end