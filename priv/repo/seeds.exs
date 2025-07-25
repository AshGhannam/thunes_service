# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ThunesService.Repo.insert!(%ThunesService.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ThunesService.Accounts

# Create admin user for testing
user =
  case Accounts.get_user_by_email("admin@example.com") do
    nil ->
      {:ok, user} = Accounts.register_user(%{email: "admin@example.com"})
      user

    existing_user ->
      existing_user
  end

{:ok, {_user, _expired_tokens}} =
  Accounts.update_user_password(user, %{password: "adminpassword123"})

IO.puts("Seeded admin user: admin@example.com with password: adminpassword123")
