#
# Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
# For more information visit http://www.chaibio.com
#
# Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#require 'rserve'

class MainController < ApplicationController
  api :GET, "/welcome", "Show this page when there is no user in the database"
  def welcome
    if User.empty?
      render_public_index_html
    else
      redirect_to login_path
    end
  end

  api :GET, "/login", "Show this page when there are users in the database and user is not logged in"
  def login
    if !params[:token].blank?
      cookies.permanent[:authentication_token] = params[:token]
      redirect_to root_path
    elsif !User.empty?
      render_public_index_html
    else
      redirect_to welcome_path
    end
  end
  
end