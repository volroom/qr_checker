defmodule QrSharerWeb.CardsLive do
  @moduledoc """
  Main view of cards
  """
  use QrSharerWeb, :live_view
  alias QrSharer.LoyaltyCards
  alias QrSharer.LoyaltyCards.LoyaltyCard

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    # get cards and assign
    cards = LoyaltyCards.list_cards()
    changeset = LoyaltyCard.changeset(%LoyaltyCard{}, %{})

    socket
    |> assign(:cards, cards)
    |> assign(:changeset, changeset)
    |> assign(:qr_code, nil)
    |> assign(:user_id, user_id)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("reveal_qr", %{"reveal_qr" => params}, socket) do
    socket =
      case QrSharer.LoyaltyCards.Server.get_qr_code(params["card_id"], socket.assigns.user_id) do
        {:ok, qr_code} ->
          socket
          |> clear_flash()
          |> assign(:qr_code, qr_code)

        {:error, :card_not_cooled_down} ->
          put_flash(socket, :error, "Please wait for the card to be ready to use again")

        {:error, :no_uses_remaing} ->
          put_flash(socket, :error, "Card has no uses remaining, please try another one")
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"loyalty_card" => form}, socket) do
    case LoyaltyCards.create_loyalty_card(form, socket.assigns.user_id) do
      {:ok, new_card} ->
        # TODO: clear modal after a delay to prevent screenshotting

        socket
        |> update(:cards, &[new_card | &1])
        |> assign(:changeset, LoyaltyCard.changeset(%LoyaltyCard{}, %{}))
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h3>NB! Please do not screenshot the QR codes since they can't be tracked if they're external to this system</h3>
    <.hidable_section label="Add Loyalty Card" toggle_id={get_toggle_id()}>
      <.add_card_form changeset={@changeset} />
    </.hidable_section>
    <br>
    <.qr_code_modal qr_code={@qr_code} />
    <h2>Loyalty Cards:</h2>
    <ul>
      <%= for card <- @cards do %>
        <.card card={card} user_id={@user_id} />
      <% end %>
    </ul>
    """
  end

  def qr_code_modal(assigns) do
    ~H"""
    <%= if @qr_code != nil do %>
      <div id="myModal" class="modal">
        <div class="modal-content">
          <img src={"data:image/svg+xml;base64, #{@qr_code}"} style="width:100%;height:100%" />
        </div>
      </div>
    <% end %>
    """
  end

  def add_card_form(assigns) do
    ~H"""
    <.form let={f} for={@changeset} phx-submit="save">
      <.input_group form={f} field={:name} label="Card name" />
      <.input_group form={f} field={:cooldown_minutes} label="Cooldown in minutes" />
      <.input_group form={f} field={:max_uses} label="Max Uses" />
      <.input_group form={f} field={:owner_quota} label="Owner Quota" />
      <.input_group form={f} field={:qr_data} label="QR Data" />

      <%= submit "Add" %>
    </.form>
    """
  end

  def card(assigns) do
    assigns =
      assign(
        assigns,
        :uses_remaining,
        LoyaltyCards.get_uses_remaining(assigns.card, assigns.user_id)
      )

    ~H"""
    <.hidable_section label={@card.name}>
      <span>
        Uses today: <%= @card.uses_today  %>
      </span>
      <br>
      <span>
        Uses remaining: <%= @uses_remaining  %>
      </span>
      <br>
      <span>
        Last used: <%= format_last_used(@card.last_used)  %>
      </span>
      <br>
      <%= if @uses_remaining > 0 and LoyaltyCards.card_cooled_down?(@card) do %>
        <.form let={f} for={:reveal_qr} as={:reveal_qr} phx-submit="reveal_qr">
          <%= hidden_input f, :card_id, value: @card.id %>
          <%= submit "Reveal QR Code" %>
        </.form>
      <% end %>
    </.hidable_section>
    """
  end

  def input_group(assigns) do
    ~H"""
    <%= label @form, @label %>
    <%= text_input @form, @field %>
    <%= error_tag @form, @field %>
    """
  end

  def hidable_section(assigns) do
    assigns = assign_new(assigns, :toggle_id, &get_toggle_id/0)

    ~H"""
    <label for={@toggle_id}>
      <%= @label %>
    </label>
    <input class="hidable-toggle" id={@toggle_id} type="checkbox" phx-update="ignore" />
    <div class="hidable">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp format_last_used(nil), do: "Never"

  defp format_last_used(last_used) do
    last_used
    |> Timex.Timezone.convert(Application.get_env(:qr_sharer, :timezone))
    |> Timex.format!("{h12}:{m}:{s} {AM}")
  end

  defp get_toggle_id, do: "toggle-#{UUID.uuid4()}"
end
