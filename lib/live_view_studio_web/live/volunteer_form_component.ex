defmodule LiveViewStudioWeb.VolunteerFormComponent do
  use LiveViewStudioWeb, :live_component

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(socket) do
    changeset = Volunteers.change_volunteer(%Volunteer{})

    {:ok, assign(socket, :form, to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
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
    </div>
    """
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
