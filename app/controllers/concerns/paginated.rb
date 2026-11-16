# Splits a long list into pages. The view draws the links with the shared/pagination partial.
module Paginated
  extend ActiveSupport::Concern

  private

  # Returns the records of the page asked for in params[:page] (out-of-range pages are clamped).
  def paginate(scope, per:)
    @page_count = [(scope.count.to_f / per).ceil, 1].max
    @page = params[:page].to_i.clamp(1, @page_count)
    scope.limit(per).offset((@page - 1) * per)
  end
end
