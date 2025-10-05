import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { email, otp, new_password } = await req.json();
  const supabase = createClient(
    Deno.env.get("PROJECT_URL")!,
    Deno.env.get("SERVICE_ROLE_KEY")!
  );

  const { data: record } = await supabase
    .from("password_reset")
    .select("*")
    .eq("email", email)
    .eq("otp", otp)
    .eq("used", false)
    .maybeSingle();

  if (!record)
    return new Response(JSON.stringify({ error: "Invalid or expired OTP" }), {
      status: 400,
    });

  if (new Date(record.expires_at) < new Date())
    return new Response(JSON.stringify({ error: "OTP expired" }), {
      status: 400,
    });

  // update user's password
  await supabase.auth.admin.updateUserByEmail(email, { password: new_password });

  // mark OTP as used
  await supabase.from("password_reset").update({ used: true }).eq("id", record.id);

  return new Response(JSON.stringify({ message: "Password updated successfully" }), {
    headers: { "Content-Type": "application/json" },
  });
});
