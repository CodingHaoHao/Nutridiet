import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { email, otp, new_password } = await req.json();

    const supabase = createClient(
      Deno.env.get("PROJECT_URL")!,
      Deno.env.get("SERVICE_ROLE_KEY")! // Service role key used to update password in authentication
    );

    //check the otp is valid with the email and never used
    const { data: otpRow, error: otpError } = await supabase 
      .from("password_reset")
      .select()
      .eq("email", email)
      .eq("otp", otp)
      .eq("used", false)
      .maybeSingle();

    if (otpError || !otpRow) {
      return new Response(JSON.stringify({ error: "Invalid OTP" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (new Date() > new Date(otpRow.expires_at)) {
      return new Response(JSON.stringify({ error: "OTP expired" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: account, error: accountError } = await supabase // go to get the user_id for link to authentication
      .from("account")
      .select("user_id")
      .eq("email", email)
      .maybeSingle();

    if (accountError || !account || !account.user_id) {
      return new Response(JSON.stringify({ error: "User not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // update the password with auth user in authentication
    const { data: updatedUser, error: updateError } = await supabase.auth.admin.updateUserById(account.user_id, {
      password: new_password,
    });

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    await supabase
      .from("password_reset")
      .update({ used: true })
      .eq("id", otpRow.id);

    return new Response(JSON.stringify({ message: "Password reset successfully" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
