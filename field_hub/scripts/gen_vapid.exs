# scripts/gen_vapid.exs

# Generate P-256 Key Pair
jwk = JOSE.JWK.generate_key({:ec, :secp256r1})
key_map = JOSE.JWK.to_map(jwk) |> elem(1)

# Extract coordinates for public key (Uncompressed point format: 0x04 + x + y)
x = Base.url_decode64!(key_map["x"], padding: false)
y = Base.url_decode64!(key_map["y"], padding: false)
public_key_bytes = <<0x04>> <> x <> y

# Extract private key (d)
private_key_bytes = Base.url_decode64!(key_map["d"], padding: false)

# Encode as URL-safe Base64
public_key_b64 = Base.url_encode64(public_key_bytes, padding: false)
private_key_b64 = Base.url_encode64(private_key_bytes, padding: false)

IO.puts """
VAPID Keys generated!

VAPID_PUBLIC_KEY=#{public_key_b64}
VAPID_PRIVATE_KEY=#{private_key_b64}
VAPID_SUBJECT=mailto:admin@localhost
"""
