defmodule FieldHub.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user authentication and organization management.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo

  alias FieldHub.Accounts.{User, UserToken, UserNotifier, Organization}

  # ============================================================================
  # Organization functions
  # ============================================================================

  @doc """
  Returns the list of all organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    Repo.all(Organization)
  end

  @doc """
  Gets a single organization. Raises if not found.

  ## Examples

      iex> get_organization!(123)
      %Organization{}

      iex> get_organization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Gets a single organization. Returns {:ok, org} or {:error, :not_found}.

  ## Examples

      iex> get_organization(123)
      {:ok, %Organization{}}

      iex> get_organization(456)
      {:error, :not_found}

  """
  def get_organization(id) do
    case Repo.get(Organization, id) do
      nil -> {:error, :not_found}
      org -> {:ok, org}
    end
  end

  @doc """
  Gets an organization by its slug.

  ## Examples

      iex> get_organization_by_slug("ace-hvac")
      {:ok, %Organization{}}

      iex> get_organization_by_slug("non-existent")
      {:error, :not_found}

  """
  def get_organization_by_slug(slug) when is_binary(slug) do
    case Repo.get_by(Organization, slug: slug) do
      nil -> {:error, :not_found}
      org -> {:ok, org}
    end
  end

  @doc """
  Creates a new organization with trial subscription.

  Sets trial_ends_at to 14 days from now.

  ## Examples

      iex> create_organization(%{name: "Ace HVAC", slug: "ace-hvac"})
      {:ok, %Organization{}}

      iex> create_organization(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs) do
    trial_ends_at = DateTime.utc_now() |> DateTime.add(14, :day) |> DateTime.truncate(:second)

    # Handle both string and atom keys
    attrs =
      if is_map(attrs) && Enum.any?(Map.keys(attrs), &is_binary/1) do
        Map.put(attrs, "trial_ends_at", trial_ends_at)
      else
        Map.put(attrs, :trial_ends_at, trial_ends_at)
      end

    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an organization and assigns the user as owner.

  Uses Ecto.Multi to ensure both operations succeed or rollback.

  ## Examples

      iex> create_organization_with_owner(%{name: "Ace HVAC", slug: "ace-hvac"}, user)
      {:ok, %{organization: %Organization{}, user: %User{}}}

  """
  def create_organization_with_owner(org_attrs, %User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:organization, fn _repo, _changes ->
      create_organization(org_attrs)
    end)
    |> Ecto.Multi.run(:user, fn _repo, %{organization: org} ->
      user
      |> Ecto.Changeset.change(organization_id: org.id, role: "owner")
      |> Repo.update()
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates an organization.

  Note: slug cannot be changed after creation.

  ## Examples

      iex> update_organization(organization, %{name: "New Name"})
      {:ok, %Organization{}}

      iex> update_organization(organization, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization(%Organization{} = org, attrs) do
    # Don't allow slug changes
    attrs = Map.drop(attrs, [:slug, "slug"])

    org
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an organization.

  ## Examples

      iex> delete_organization(organization)
      {:ok, %Organization{}}

  """
  def delete_organization(%Organization{} = org) do
    Repo.delete(org)
  end

  @doc """
  Updates organization subscription details.

  ## Examples

      iex> update_subscription(org, %{subscription_tier: "growth", subscription_status: "active"})
      {:ok, %Organization{}}

  """
  def update_subscription(%Organization{} = org, attrs) do
    org
    |> Ecto.Changeset.change(Map.to_list(attrs))
    |> Repo.update()
  end

  @doc """
  Generates a unique slug from an organization name.

  If the slug already exists, appends a unique suffix.

  ## Examples

      iex> generate_unique_slug("Ace HVAC")
      "ace-hvac"

      iex> generate_unique_slug("Ace HVAC") # when "ace-hvac" exists
      "ace-hvac-abc123"

  """
  def generate_unique_slug(name) when is_binary(name) do
    base_slug = Organization.generate_slug(name)

    case Repo.get_by(Organization, slug: base_slug) do
      nil ->
        base_slug

      _exists ->
        suffix =
          :crypto.strong_rand_bytes(4)
          |> Base.url_encode64()
          |> String.downcase()
          |> String.slice(0, 6)

        "#{base_slug}-#{suffix}"
    end
  end

  @doc """
  Checks if an organization has an active subscription.

  Returns true if:
  - subscription_status is "active"
  - subscription_status is "trial" and trial hasn't expired

  ## Examples

      iex> organization_active?(active_org)
      true

      iex> organization_active?(cancelled_org)
      false

  """
  def organization_active?(%Organization{} = org) do
    case org.subscription_status do
      "active" ->
        true

      "trial" ->
        org.trial_ends_at && DateTime.compare(org.trial_ends_at, DateTime.utc_now()) == :gt

      _ ->
        false
    end
  end

  # ============================================================================
  # User functions
  # ============================================================================

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `FieldHub.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `FieldHub.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
