defmodule QrSharerWeb.CardsLive do
  @moduledoc """
  Main view of cards
  """
  use QrSharerWeb, :live_view
  alias QrSharer.LoyaltyCards
  alias QrSharer.LoyaltyCards.LoyaltyCard

  @thirty_seconds_in_ms 30_000

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    # get cards and assign
    cards = Enum.into(LoyaltyCards.list_cards(), %{}, fn card -> {card.id, card} end)
    changeset = LoyaltyCard.changeset(%LoyaltyCard{}, %{})
    Phoenix.PubSub.subscribe(QrSharer.PubSub, "update_cards")

    socket
    |> assign(:cards, cards)
    |> assign(:changeset, changeset)
    |> assign(:qr_code, nil)
    |> assign(:user_id, user_id)
    |> then(&{:ok, &1})
  end

  # TODO: check card update after reveal
  @impl true
  def handle_event("reveal_qr", %{"reveal_qr" => %{"card_id" => card_id}}, socket) do
    %{assigns: %{user_id: user_id}} = socket

    with {:ok, qr_code, card} <- QrSharer.LoyaltyCards.Server.get_qr_code(card_id, user_id),
         :ok <- broadcast_card(card) do
      Process.send_after(self(), :hide_qr, @thirty_seconds_in_ms)

      socket
      |> clear_flash()
      |> assign(:card, card)
      |> assign(:qr_code, qr_code)
      |> then(&{:noreply, &1})
    else
      {:error, :card_not_cooled_down} ->
        show_error(socket, "Please wait for the card to be ready to use again")

      {:error, :no_uses_remaing} ->
        show_error(socket, "Card has no uses remaining, please try another one")

      _error ->
        show_error(socket, "Error showing QR code, please refresh and try again")
    end
  end

  def handle_event("save", %{"loyalty_card" => form}, socket) do
    with {:ok, new_card} <- LoyaltyCards.create_loyalty_card(form, socket.assigns.user_id),
         {:ok, _pid} <- QrSharer.LoyaltyCards.Supervisor.add_card_server(new_card),
         :ok <- broadcast_card(new_card) do
      socket
      |> clear_flash()
      |> update(:cards, &[new_card | &1])
      |> assign(:changeset, LoyaltyCard.changeset(%LoyaltyCard{}, %{}))
      |> then(&{:noreply, &1})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> then(&{:noreply, &1})

      _error ->
        show_error(socket, "Error adding card, please refresh and try again")
    end
  end

  @impl true
  def handle_info(:hide_qr, socket) do
    {:noreply, assign(socket, :qr_code, nil)}
  end

  def handle_info({:update_cards, card}, socket) do
    socket
    |> update(:cards, &Map.merge(&1, %{card.id => card}))
    |> then(&{:noreply, &1})
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
      <%= for {_card_id, card} <- @cards do %>
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

  # TODO: stop updates from wiping form
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
      <%= if LoyaltyCards.card_cooled_down?(@card) do %>
        <%= if @uses_remaining > 0 do %>
          <.form let={f} for={:reveal_qr} as={:reveal_qr} phx-submit="reveal_qr">
            <%= hidden_input f, :card_id, value: @card.id %>
            <%= submit "Reveal QR Code" %>
          </.form>
        <% end %>
      <% else %>
        <strong>Please wait for card to be ready again</strong>
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

  defp broadcast_card(card) do
    Phoenix.PubSub.broadcast_from(QrSharer.PubSub, self(), "update_cards", {:update_cards, card})
  end

  defp show_error(socket, error_msg) do
    socket
    |> put_flash(:error, error_msg)
    |> then(&{:noreply, &1})
  end
end
