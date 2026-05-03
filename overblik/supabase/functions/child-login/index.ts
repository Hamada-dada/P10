import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

if (!supabaseUrl || !serviceRoleKey || !anonKey) {
  throw new Error(
    "Missing SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, or SUPABASE_ANON_KEY",
  );
}

const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

const publicClient = createClient(supabaseUrl, anonKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function randomPassword(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);

  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function childEmail(profileId: string): string {
  return `child-${profileId}@children.overblik.invalid`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();

    const familyCode = String(body.family_code ?? "")
      .trim()
      .toUpperCase();

    const childCode = String(body.child_code ?? "").trim();

    if (!familyCode || !childCode) {
      return jsonResponse({ error: "Invalid child credentials" }, 401);
    }

    const { data: family, error: familyError } = await admin
      .from("families")
      .select("id")
      .eq("family_code", familyCode)
      .maybeSingle();

    if (familyError) {
      console.error("family lookup failed", familyError);
      return jsonResponse({ error: "Login failed" }, 500);
    }

    if (!family) {
      return jsonResponse({ error: "Invalid child credentials" }, 401);
    }

    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select(
        "id, family_id, auth_user_id, name, display_name, emoji, role, is_active",
      )
      .eq("family_id", family.id)
      .eq("child_login_code", childCode)
      .in("role", ["child_limited", "child_extended"])
      .eq("is_active", true)
      .maybeSingle();

    if (profileError) {
      console.error("profile lookup failed", profileError);
      return jsonResponse({ error: "Login failed" }, 500);
    }

    if (!profile) {
      return jsonResponse({ error: "Invalid child credentials" }, 401);
    }

    const email = childEmail(profile.id);
    const temporaryPassword = randomPassword();

    let authUserId = profile.auth_user_id as string | null;

    if (!authUserId) {
      const { data: createdUser, error: createUserError } =
        await admin.auth.admin.createUser({
          email,
          password: temporaryPassword,
          email_confirm: true,
          user_metadata: {
            profile_id: profile.id,
            family_id: profile.family_id,
            role: profile.role,
            login_type: "child",
          },
        });

      if (createUserError || !createdUser.user) {
        console.error("create child auth user failed", createUserError);
        return jsonResponse({ error: "Login failed" }, 500);
      }

      authUserId = createdUser.user.id;

      const { error: updateProfileError } = await admin
        .from("profiles")
        .update({ auth_user_id: authUserId })
        .eq("id", profile.id);

      if (updateProfileError) {
        console.error("attach child auth user failed", updateProfileError);
        return jsonResponse({ error: "Login failed" }, 500);
      }
    } else {
      const { error: updateUserError } = await admin.auth.admin.updateUserById(
        authUserId,
        {
          email,
          password: temporaryPassword,
          email_confirm: true,
          user_metadata: {
            profile_id: profile.id,
            family_id: profile.family_id,
            role: profile.role,
            login_type: "child",
          },
        },
      );

      if (updateUserError) {
        console.error("update child auth user failed", updateUserError);
        return jsonResponse({ error: "Login failed" }, 500);
      }
    }

    const { data: signInData, error: signInError } =
      await publicClient.auth.signInWithPassword({
        email,
        password: temporaryPassword,
      });

    if (signInError || !signInData.session) {
      console.error("child sign in failed", signInError);
      return jsonResponse({ error: "Login failed" }, 500);
    }

    return jsonResponse({
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
      expires_at: signInData.session.expires_at,
      profile: {
        profile_id: profile.id,
        family_id: profile.family_id,
        name: profile.name,
        display_name: profile.display_name,
        emoji: profile.emoji,
        role: profile.role,
      },
    });
  } catch (error) {
    console.error("child-login failed", error);
    return jsonResponse({ error: "Login failed" }, 500);
  }
});