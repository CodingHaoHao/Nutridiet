import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "npm:resend";

serve(async (req) => {
  const { email } = await req.json();
  const supabase = createClient(
    Deno.env.get("PROJECT_URL")!,
    Deno.env.get("SERVICE_ROLE_KEY")!
  );

  // Check if email exists in account table
  const { data: user } = await supabase
    .from("account")
    .select("email")
    .eq("email", email)
    .maybeSingle();

  if (!user) {
    return new Response("Email not found", { status: 404 });
  }

  // Generate random 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await supabase.from("password_reset").insert({
    email,
    otp,
    expires_at: new Date(Date.now() + 10 * 60 * 1000).toISOString(), // expired in 10 minutes
    used: false,
  });

  // Send OTP via Resend API
  const resend = new Resend(Deno.env.get("RESEND_API_KEY")!);

  await resend.emails.send({
    from: "onboarding@resend.dev",
    to: email,
    subject: "NutriDiet Password Reset OTP",
    html: `<p>Your OTP code is <strong>${otp}</strong>. It will expire in 10 minutes.</p>`,
  });

  return new Response(
    JSON.stringify({ message: "OTP sent successfully" }),
    { headers: { "Content-Type": "application/json" } }
  );
});
