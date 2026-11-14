class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:faq, :about, :contact]

  def login; end
  def faq; end
  def about; end
  def contact; end
end
