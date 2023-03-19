defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers
  alias LiveViewStudioWeb.ServerFormComponent

  def mount(_params, _session, socket) do
    servers = Servers.list_servers()

    socket =
      assign(socket,
        servers: servers,
        coffees: 0
      )

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    server = Servers.get_server!(id)

    {:noreply,
     assign(socket,
       selected_server: server,
       page_title: "What's up #{server.name}?"
     )}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  attr :server, Servers.Server, required: true

  def server(assigns) do
    ~H"""
    <div class="server">
      <div class="header">
        <h2><%= @server.name %></h2>
        <button
          class={@server.status}
          phx-click="toggle-status"
          phx-value-id={@server.id}
        >
          <%= @server.status %>
        </button>
      </div>
      <div class="body">
        <div class="row">
          <span>
            <%= @server.deploy_count %> deploys
          </span>
          <span>
            <%= @server.size %> MB
          </span>
          <span>
            <%= @server.framework %>
          </span>
        </div>
        <h3>Last Commit Message:</h3>
        <blockquote>
          <%= @server.last_commit_message %>
        </blockquote>
      </div>
    </div>
    """
  end

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  def handle_event("toggle-status", %{"id" => id}, socket) do
    server = Servers.get_server!(id)

    # Update the server's status to the opposite of its current status:

    new_status = if server.status == "up", do: "down", else: "up"

    {:ok, server} =
      Servers.update_server(
        server,
        %{status: new_status}
      )

    # Assign the updated server as the selected server so
    # that the server details re-render:

    socket = assign(socket, selected_server: server)

    # Three ways to update the server's red/green
    # status indicator in the sidebar:

    # 1. Refetch the list of servers and assign them back.

    socket = assign(socket, :servers, Servers.list_servers())

    # 2. Or, to avoid another database hit, find the matching
    # server in the current list of servers, replace it, and
    # assign the resulting list back:

    servers =
      Enum.map(socket.assigns.servers, fn s ->
        if s.id == server.id, do: server, else: s
      end)

    socket = assign(socket, servers: servers)

    # 3. Here's another way to do the same thing without
    # having to assign the servers back to the socket:

    socket =
      update(socket, :servers, fn servers ->
        for s <- servers do
          if s.id == server.id, do: server, else: s
        end
      end)

    {:noreply, socket}
  end

  def handle_info({ServerFormComponent, :server_created, server}, socket) do
    socket =
      update(
        socket,
        :servers,
        fn servers -> [server | servers] end
      )

    socket = push_patch(socket, to: ~p"/servers/#{server}")

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, selected_server: hd(socket.assigns.servers))
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, selected_server: nil)
  end
end
