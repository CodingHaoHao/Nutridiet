import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { email } = await req.json();

    // Connect to Supabase using service key
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Check if email exists in account table
    const { data: user, error: userError } = await supabase
      .from("account")
      .select("user_id")
      .eq("email", email)
      .maybeSingle();

    if (userError) throw userError;
    if (!user) {
      return new Response(
        JSON.stringify({ error: "Email not found" }),
        { status: 404 }
      );
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    // Store OTP in password_reset table
    await supabase.from("password_reset").insert([
      { email, otp, expires_at: expiresAt, used: false },
    ]);

    console.log(`OTP for ${email}: ${otp}`);

    return new Response(
      JSON.stringify({ message: "OTP generated successfully", otp }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error(error);
    return new Response(
      JSON.stringify({ error: "Server error" }),
      { status: 500 }
    );
  }
});
