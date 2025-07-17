defmodule ThunesServiceWeb.PageController do
  use ThunesServiceWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
