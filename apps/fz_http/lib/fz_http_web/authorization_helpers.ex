defmodule FzHttpWeb.AuthorizationHelpers do
  @moduledoc """
  Authorization-related helpers
  """
  use FzHttpWeb, :helper
  import Phoenix.LiveView

  def not_authorized(socket) do
    socket
    |> put_flash(:error, "Not authorized.")
    |> redirect(to: ~p"/")
  end
end
