defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(_params, _session, socket) do
    volunteers = Volunteers.list_volunteers()

    changeset = Volunteers.change_volunteer(%Volunteer{})

    socket =
      socket
      |> stream(:volunteers, volunteers)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Volunteer Check-In</h1>
    <div id="volunteer-checkin">
      <.form for={@form} phx-submit="save" phx-change="validate">
        <.input
          field={@form[:name]}
          placeholder="Name"
          autocomplete="off"
          phx-debounce="2000"
        />
        <.input
          field={@form[:phone]}
          type="tel"
          placeholder="Phone"
          autocomplete="off"
          phx-debounce="blur"
        />
        <.button phx-disable-with="Saving...">
          Check In
        </.button>
      </.form>

      <div id="volunteers" phx-update="stream">
        <div
          :for={{volunteer_id, volunteer} <- @streams.volunteers}
          class={"volunteer #{if volunteer.checked_out, do: "out"}"}
          id={volunteer_id}
        >
          <div class="name">
            <%= volunteer.name %>
          </div>
          <div class="phone">
            <%= volunteer.phone %>
          </div>
          <div class="status">
            <button phx-click="toggle-status" phx-value-id={volunteer.id}>
              <%= if volunteer.checked_out,
                do: "Check In",
                else: "Check Out" %>
            </button>
          </div>
          <.link
            class="delete"
            phx-click="delete"
            phx-value-id={volunteer.id}
            data-confirm="Are you sure?"
          >
            <.icon name="hero-trash-solid" />
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("toggle-status", %{"id" => volunteer_id}, socket) do
    volunteer = Volunteers.get_volunteer!(volunteer_id)
    {:ok, volunteer} = Volunteers.toggle_status_volunteer(volunteer)

    {:noreply, stream_insert(socket, :volunteers, volunteer)}
  end

  def handle_event("delete", %{"id" => volunteer_id}, socket) do
    volunteer = Volunteers.get_volunteer!(volunteer_id)
    {:ok, _} = Volunteers.delete_volunteer(volunteer)

    {:noreply, stream_delete(socket, :volunteers, volunteer)}
  end

  def handle_event("validate", %{"volunteer" => volunteer_params}, socket) do
    changeset =
      %Volunteer{}
      |> Volunteers.change_volunteer(volunteer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:ok, volunteer} ->
        socket =
          socket
          |> stream_insert(:volunteers, volunteer, at: 0)
          |> put_flash(:info, "Volunteer successfully checked in!")

        changeset = Volunteers.change_volunteer(%Volunteer{})

        {:noreply, assign_form(socket, changeset)}

      {:error, changeset} ->
        socket = put_flash(socket, :error, "Volunteer has not successfully checked in!")

        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
